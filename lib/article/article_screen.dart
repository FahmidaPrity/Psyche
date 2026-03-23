import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/bottom_navbar.dart';
import 'article_detail.dart';
import 'dart:ui';

class ArticleScreen extends StatefulWidget {
  const ArticleScreen({super.key});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> articles = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchArticles();
  }

  Future<void> fetchArticles() async {
    try {
      final response = await supabase
          .from('articles')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        articles = List<Map<String, dynamic>>.from(response as List);
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
      appBar: AppBar(title: const Text("Articles Corner!")),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/backgrounds/bg_article.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(color: Colors.white.withOpacity(0.25)),
          ),
          loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(child: Text('Error: $error'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final a = articles[index];
                    final title = a['title'] ?? '';
                    final subtitle = a['subtitle'] ?? '';
                    final imageUrl = a['image_url'] as String?;
                    final content = a['content'] ?? '';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ArticleDetail(
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
                                      const Icon(Icons.image),
                                ),
                              )
                            else
                              const Icon(Icons.article, size: 40),
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
