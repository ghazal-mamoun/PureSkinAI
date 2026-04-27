import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pure_skin_ai/auth/login_page.dart';

class ProductPage extends StatefulWidget {
  final List<Map<String, dynamic>> results;
  const ProductPage({super.key, required this.results});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  bool _isCheckingAuth = true; // حالة التحقق من الهوية

  @override
  void initState() {
    super.initState();
    _checkGuestStatus();
  }

  Future<void> _checkGuestStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // جلب القيمة، إذا كانت فارغة نعتبرها false (ضيف)
    bool isLogin = prefs.getBool('isLogin') ?? false; 
    
    if (!isLogin) {
      // إذا كان ضيفاً، نطرده فوراً لصفحة تسجيل الدخول ونمسح الـ Navigator
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LogIn()),
          (Route<dynamic> route) => false,
        );
      }
    } else {
      // مستخدم رسمي، نسمح له برؤية الصفحة
      setState(() {
        _isCheckingAuth = false;
      });
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color mainColor = Color(0xFF5F8063);

    // إذا كان لا يزال يتحقق، يظهر مؤشر تحميل فقط
    if (_isCheckingAuth) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: mainColor)),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: mainColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Recommendations', style: TextStyle(color: mainColor, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/bac1.jpeg', fit: BoxFit.cover)),
          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('pure skin').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: mainColor));
                }

                var allDocs = snapshot.data?.docs ?? [];

                return ListView.builder(
                  itemCount: widget.results.length,
                  itemBuilder: (context, index) {
                    String fullLabel = widget.results[index]['label'];
                    String searchKey = fullLabel.split(' ').first;

                    var categoryProducts = allDocs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      String dbSkinType = (data['Skin_Type'] ?? '').toString();
                      String dbConcern = (data['Concern'] ?? '').toString();
                      return dbSkinType.contains(searchKey) || dbConcern.contains(searchKey);
                    }).toList();

                    if (categoryProducts.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                          child: Text(
                            "$fullLabel Products",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: mainColor),
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.55,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: categoryProducts.length,
                          itemBuilder: (context, i) {
                            var product = categoryProducts[i].data() as Map<String, dynamic>;
                            return _buildProductCard(product);
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          Expanded(child: Padding(padding: const EdgeInsets.all(8), child: Image.network(product['Image_URL'] ?? '', fit: BoxFit.contain))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(product['Product_Name'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), maxLines: 2),
          ),
          _buildShopButton("Amazon", Colors.orange, product['Amazon_Link']),
          _buildShopButton("Nahdi", const Color(0xFF235DAA), product['Nahdi_Link']),
          _buildShopButton("Nice One", Colors.black, product['Nice_One_Link (EN)']),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildShopButton(String label, Color color, String? url) {
    if (url == null || url.isEmpty || url == "null") return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: SizedBox(
        width: double.infinity,
        height: 25,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: color, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
          onPressed: () => _launchURL(url),
          child: Text(label, style: const TextStyle(fontSize: 9, color: Colors.white)),
        ),
      ),
    );
  }
}