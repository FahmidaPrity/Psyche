import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'book_detail.dart';
import '../resources/resource_service.dart';
import '../widgets/bottom_navbar.dart';

class LibraryScreen extends StatefulWidget {
  final String title;
  const LibraryScreen({super.key, required this.title});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final supabase = Supabase.instance.client;
  final ResourceService _service = ResourceService();

  List<Map<String, dynamic>> books = [];
  bool loading = true;
  String? error;
  Set<String> favoriteKeys = {};
  Set<String> bookmarkKeys = {};

  @override
  void initState() {
    super.initState();
    fetchBooks();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    try {
      favoriteKeys = await _service.fetchFavoriteKeys();
      bookmarkKeys = await _service.fetchBookmarkKeys();
      setState(() {});
    } catch (_) {}
  }

  Future<void> fetchBooks() async {
    try {
      final response = await supabase
          .from('books')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        books = List<Map<String, dynamic>>.from(response);
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  bool _isFavorited(String id, String type) =>
      favoriteKeys.contains('$id|$type');
  bool _isBookmarked(String id, String type) =>
      bookmarkKeys.contains('$id|$type');

  Future<void> _toggleFavorite(String id, String type) async {
    final key = '$id|$type';
    if (supabase.auth.currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You must be logged in.')));
      return;
    }
    setState(() {
      if (_isFavorited(id, type)) {
        favoriteKeys.remove(key);
      } else {
        favoriteKeys.add(key);
      }
    });
    try {
      if (_isFavorited(id, type)) {
        await _service.addFavorite(id, type);
      } else {
        await _service.removeFavorite(id, type);
      }
      favoriteKeys = await _service.fetchFavoriteKeys();
      setState(() {});
    } catch (e) {
      setState(() {
        if (_isFavorited(id, type)) {
          favoriteKeys.remove(key);
        } else {
          favoriteKeys.add(key);
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Favorite update failed: $e')));
    }
  }

  Future<void> _toggleBookmark(String id, String type) async {
    if (supabase.auth.currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You must be logged in.')));
      return;
    }
    final currently = _isBookmarked(id, type);
    if (!currently) {
      final note = await _askNoteDialog();
      try {
        await _service.addBookmark(id, type, note: note);
        bookmarkKeys = await _service.fetchBookmarkKeys();
        setState(() {});
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Bookmark failed: $e')));
      }
    } else {
      try {
        await _service.removeBookmark(id, type);
        bookmarkKeys = await _service.fetchBookmarkKeys();
        setState(() {});
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Remove bookmark failed: $e')));
      }
    }
  }

  Future<String?> _askNoteDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add a note"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Write a short note..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Skip"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Save"),
          ),
        ],
      ),
    );
    return (result == null || result.isEmpty) ? null : result;
  }

  static const _headerBorderRadius = BorderRadius.only(
    bottomLeft: Radius.circular(30),
    bottomRight: Radius.circular(30),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/backgrounds/bg_library.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(color: Colors.white.withOpacity(0.2)),
          ),
          Column(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFC5E5D2),
                      Color.fromARGB(255, 161, 228, 205),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: _headerBorderRadius,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: _headerBorderRadius,
                        child: Opacity(
                          opacity: 0.2,
                          child: Image.asset(
                            "assets/images/icons/lib_top.gif",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(
                        top: 40,
                        left: 16,
                        right: 16,
                        bottom: 20,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.black,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(flex: 2),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 10),
                              const Text(
                                "Minilib",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const Text(
                                "The Chosen Ones...",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(flex: 3),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : error != null
                    ? Center(child: Text('Error: $error'))
                    : books.isEmpty
                    ? const Center(child: Text('No books found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final b = books[index];
                          final imageUrl = b['image_url'] as String?;
                          return _buildRemoteTile(context, b, imageUrl);
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildRemoteTile(
    BuildContext context,
    Map<String, dynamic> book,
    String? imageUrl,
  ) {
    final id = (book['id'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFC5E5D2).withOpacity(0.8),
            const Color(0xFF738085).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade400,
            blurRadius: 6,
            spreadRadius: 2,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: 50,
                  height: 60,
                )
              : const SizedBox(
                  width: 50,
                  height: 60,
                  child: Center(child: Icon(Icons.book, color: Colors.white)),
                ),
        ),
        title: Text(
          book['title'] ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          book['author'] ?? 'Unknown Author',
          style: const TextStyle(color: Colors.black54), // Better contrast
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                _isFavorited(id, 'book') ? Icons.star : Icons.star_border,
                color: _isFavorited(id, 'book') ? Colors.amber : Colors.black54,
              ),
              onPressed: () => _toggleFavorite(id, 'book'),
            ),
            IconButton(
              icon: Icon(
                _isBookmarked(id, 'book')
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                color: _isBookmarked(id, 'book') ? Colors.blue : Colors.black54,
              ),
              onPressed: () => _toggleBookmark(id, 'book'),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.black54),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetail(
                title: book['title'] ?? '',
                author: book['author'] ?? 'Unknown Author',
                imagePath: book['image_url'] ?? '',
                progress: 0.0,
                description: book['description'] ?? 'No description available.',
                pages: (book['pages'] != null)
                    ? int.tryParse(book['pages'].toString()) ?? 0
                    : 0,
                publishedDate: book['published_date'] ?? 'N/A',
                pdfUrl: book['pdf_url'] ?? '',
              ),
            ),
          );
        },
      ),
    );
  }
}
