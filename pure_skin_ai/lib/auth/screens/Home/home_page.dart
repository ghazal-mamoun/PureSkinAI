import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pure_skin_ai/auth/screens/product/product.dart';
import 'package:pure_skin_ai/classifier.dart';
import 'package:pure_skin_ai/auth/screens/profile/profile_page.dart';
import 'package:pure_skin_ai/auth/screens/routen/routen_page.dart';
import 'package:pure_skin_ai/auth/screens/products/product_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pure_skin_ai/auth/login_page.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}
// ... (المكتبات والـ Imports تبقى كما هي)

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0; 

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return const AnalysisView(); 
      case 1:
        // استدعاء الصفحة التي طلبتِها مع بقاء الشريط السفلي
        return const Product(); 
      case 2:
        return const RoutinePage();
      case 3:
        return const ProfilePage();
      default:
        return const AnalysisView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
  if (index == 1) {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // إذا كان ضيفاً، ستكون القيمة false
    bool isLogIn = prefs.getBool('isLogIn') ?? false; 
    
    if (!isLogIn) {
      // الضيف يمنع من دخول المنتجات ويحول للوجن
      if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Sorry, you must log in to see all products."),
                  backgroundColor: Color(0xFF5E8C61),
                ),
              );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LogIn()),
      );
      return; 
    }
  }



          // --- إذا كان مسجلاً أو اختار أي صفحة أخرى ---
          setState(() {
            _currentIndex = index; // سيفتح صفحة product.dart والشريط موجود
          });
        },
        backgroundColor: const Color(0xFF5E8C61), // لون الشريط أخضر
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed, 
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.local_mall_outlined), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.event_repeat_outlined), label: 'Routine'),
          BottomNavigationBarItem(icon: Icon(Icons.person_2_outlined), label: 'Profile'),
        ],
      ),
    );
  }
}

// كلاس AnalysisView يبقى كما هو دون تغيير
class AnalysisView extends StatefulWidget {
  const AnalysisView({super.key});

  @override
  State<AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends State<AnalysisView> {
  File? _image;
  final picker = ImagePicker();
  String _statusText = "Please attach a photo to analyze \n your skin with AI";
  List<Map<String, dynamic>> _results = []; 
  bool _isAnalysisLoading = false;
  final SkinClassifier _classifier = SkinClassifier();
  final Color themeColor = const Color(0xFF5E8C61);

  @override
  void initState() {
    super.initState();
    _classifier.loadModel();
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isAnalysisLoading = true;
        _results = [];
        _statusText = "AI is analyzing...";
      });

      try {
        final result = await _classifier.predict(_image!);
        setState(() {
          _isAnalysisLoading = false;
          _results = result;
          _statusText = _results.isEmpty ? "Skin looks clear!" : "Analysis complete:";
        });
      } catch (e) {
        setState(() { 
          _isAnalysisLoading = false; 
          _statusText = "Error in analysis"; 
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage('assets/bac1.jpeg'), fit: BoxFit.cover),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text("Pure Skin AI", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: themeColor)),
            const SizedBox(height: 20),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _image != null 
                        ? Image.file(_image!, height: 200, width: double.infinity, fit: BoxFit.cover)
                        : Container(height: 200, color: Colors.white, child: Icon(Icons.face_retouching_natural, size: 90, color: themeColor)),
                    ),
                    const SizedBox(height: 15),
                    Text(_statusText, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                    
                    if (_isAnalysisLoading)
                      const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: CircularProgressIndicator(),
                      ),

                    ..._results.map((res) => Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(10)),
                      child: Text("${res['label']}: ${res['score']}%", style: const TextStyle(color: Colors.white)),
                    )),
                    
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image, color: Colors.white),
                      label: const Text("Upload from Gallery", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: themeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            if (_results.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductPage(results: _results),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      border: Border.all(color: themeColor, width: 2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Center(
                      child: Text(
                        "Shop Recommended Products", 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                ),
              ),
            
            const Spacer(),
            const Padding(
              padding: EdgeInsets.fromLTRB(30, 0, 30, 10),
              child: Text(
                "⚠️ Note: Analysis results are for guidance purposes only and do not replace professional medical consultation.",
                textAlign: TextAlign.center, 
                style: TextStyle(fontSize: 17, color: Colors.grey)
              ),
            ),
          ],
        ),
      ),
    );
  }
}