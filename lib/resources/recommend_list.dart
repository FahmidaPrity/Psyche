import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/bottom_navbar.dart';
import 'recommend_detail.dart';

class RecommendList extends StatefulWidget {
  const RecommendList({super.key});

  @override
  State<RecommendList> createState() => _RecommendListState();
}

class _RecommendListState extends State<RecommendList> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> items = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final response = await supabase
          .from('recommended_articles')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        items = List<Map<String, dynamic>>.from(response as List);
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recommended Reads!")),
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/backgrounds/bg_article.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
            child: Container(color: Colors.white.withOpacity(0.25)),
          ),
          // Main content
          loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(child: Text("Error: $error"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final rec = items[index];
                    final title = rec['title'] ?? '';
                    final subtitle = rec['subtitle'] ?? '';
                    final imageUrl = rec['image_url'] as String?;
                    final content = rec['content'] ?? '';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecommendDetail(
                              title: title,
                              content: content,
                              imageUrl: imageUrl,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            if (imageUrl != null && imageUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  height: 60,
                                  width: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.image, size: 40),
                                ),
                              )
                            else
                              const Icon(Icons.recommend, size: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (subtitle.isNotEmpty)
                                    Text(
                                      subtitle,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text("Learn More"),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
}
