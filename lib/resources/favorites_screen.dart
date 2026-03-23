import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../article/article_detail.dart';
import '../library/book_detail.dart';
import 'recommend_detail.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('favorites')
        .select()
        .eq('user_id', user.id);

    setState(() {
      favorites = List<Map<String, dynamic>>.from(response);
    });
  }

  void _openDetail(Map<String, dynamic> item) {
    final type = item['item_type'] ?? 'article';
    final title = item['title'] ?? '';
    final content = item['content'] ?? '';
    final imageUrl = item['image_url'] ?? '';
    if (type == 'book') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookDetail(
            title: title,
            author: item['author'] ?? 'Unknown',
            imagePath: imageUrl,
            progress: item['progress'] ?? 0.0,
            description: item['description'] ?? '',
            pages: item['pages'] ?? 100,
            publishedDate: item['published_date'] ?? '',
            pdfUrl: item['pdf_url'] ?? '',
          ),
        ),
      );
    } else if (type == 'recommended') {
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
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ArticleDetail(title: title, content: content, imageUrl: imageUrl),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Favorites")),
      body: favorites.isEmpty
          ? const Center(child: Text("No favorites yet."))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = favorites[index];
                final title = item['title'] ?? "Untitled";
                final type = item['item_type'] ?? '';
                final imageUrl = item['image_url'] ?? '';
                return GestureDetector(
                  onTap: () => _openDetail(item),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey.shade200,
                                ),
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey.shade200,
                            ),
                      title: Text(title),
                      subtitle: Text(type),
                      trailing: const Icon(Icons.star, color: Colors.amber),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
