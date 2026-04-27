import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pure_skin_ai/auth/login_page.dart'; 

class Product extends StatefulWidget {
  const Product({super.key});

  @override
  State<Product> createState() => _ProductState();
}

class _ProductState extends State<Product> {
  String? _selectedSkinType;
  
  // القائمة المحدثة لتطابق نصوص قاعدة بياناتك (Firebase)
  final List<String> _skinTypes  = [
    'Oily',
    'Dry',
    'Normal',
    'Combination',
    'Sensitive',
  ];

  @override
  void initState() {
    super.initState();
    // 1. استدعاء التحقق هنا في البداية لضمان "طرد" الضيف فوراً
    _checkGuestStatus();
  }

  // 2. دالة التحقق من حالة الدخول (مستقلة عن الـ build)
  Future<void> _checkGuestStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLogin') ?? false; 

    if (!isLoggedIn) {
      // ننتظر حتى ينتهي التطبيق من الاستقرار ثم ننقل المستخدم
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("The link could not be opened"),
              backgroundColor: Colors.redAccent,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LogIn()),
          );
        }
      });
    }
  }

  // دالة فتح الروابط الخارجية
  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty || !urlString.startsWith('http')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("The link could not be opened")),
        );
      }
      return;
    }
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("The link could not be opened")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color mainColor = Color(0xFF5F8063);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Products',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 28),
        ),
        actions: [
          // قائمة الفلترة المنسدلة
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSkinType,
                hint: const Text("Filter", style: TextStyle(color: mainColor)),
                icon: const Icon(Icons.tune, color: mainColor),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text("All Skin", style: TextStyle(color: Colors.grey)),
                  ),
                  ..._skinTypes.map((String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  )).toList(),
                ],
                onChanged: (newValue) => setState(() => _selectedSkinType = newValue),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // صورة الخلفية
          Positioned.fill(child: Image.asset('assets/bac1.jpeg', fit: BoxFit.cover)),
          
          Column(
            children: [
              const SizedBox(height: kToolbarHeight + 40), 
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('pure skin').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: mainColor));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No products found"));
                    }

                    // منطق الفلترة برمجياً (Client-side filtering)
                    List<DocumentSnapshot> products = snapshot.data!.docs;
                    if (_selectedSkinType != null) {
                      products = products.where((doc) {
                        return doc['Skin_Type'] == _selectedSkinType;
                      }).toList();
                    }

                    if (products.isEmpty) {
                      return Center(child: Text("No products for $_selectedSkinType"));
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.5, // لضمان مساحة كافية للأزرار
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        var product = products[index].data() as Map<String, dynamic>;
                        
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // صورة المنتج
                              Expanded(
                                flex: 2,
                                child: Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    image: DecorationImage(
                                      image: NetworkImage(product['Image_URL'] ?? ''),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              // اسم المنتج
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  product['Product_Name'] ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // أزرار المواقع (تم مطابقة الأسماء مع Firebase)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    _buildShopButton("Amazon", Colors.orange, product['Amazon_Link'] ?? ''),
                                    const SizedBox(height: 4),
                                    _buildShopButton("Nahdi", const Color(0xFF235DAA), product['Nahdi_Link'] ?? ''),
                                    const SizedBox(height: 4),
                                    _buildShopButton("Nice One", Colors.black, product['Nice_One_Link (EN)'] ?? ''),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ويدجت زر الشراء
  Widget _buildShopButton(String label, Color color, String url) {
    return SizedBox(
      width: double.infinity,
      height: 28,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => _launchURL(url),
        child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }
}