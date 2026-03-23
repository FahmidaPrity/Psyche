import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../library/library_screen.dart';
import '../article/article_detail.dart';
import 'recommend_detail.dart';
import '../library/book_detail.dart';
import 'recommend_list.dart';
import '../article/article_screen.dart';
import 'resource_service.dart';
import '../widgets/bottom_navbar.dart';

class ResourceScreen extends StatefulWidget {
  const ResourceScreen({super.key});

  @override
  State<ResourceScreen> createState() => _ResourceScreenState();
}

class _ResourceScreenState extends State<ResourceScreen> {
  final ResourceService _service = ResourceService();
  late Future<List<Map<String, dynamic>>> _recommendedFuture;
  late Future<List<Map<String, dynamic>>> _articlesFuture;
  late Future<List<Map<String, dynamic>>> _libraryFuture;
  Set<String> favoriteKeys = {};
  Set<String> bookmarkKeys = {};

  String selectedTab = 'suggested';

  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;
    _recommendedFuture = _service.fetchRecommended();
    _articlesFuture = _service.fetchArticles();
    _libraryFuture = _service.fetchLibraryBooks();
    _loadKeys();
    supabase.auth.onAuthStateChange.listen((event) {
      setState(() {
        _recommendedFuture = _service.fetchRecommended();
        _articlesFuture = _service.fetchArticles();
        _libraryFuture = _service.fetchLibraryBooks();
        _loadKeys();
      });
    });
  }

  Future<void> _loadKeys() async {
    try {
      favoriteKeys = await _service.fetchFavoriteKeys();
      bookmarkKeys = await _service.fetchBookmarkKeys();
    } catch (e) {
      favoriteKeys = {};
      bookmarkKeys = {};
    } finally {
      setState(() {});
    }
  }

  bool _isFavorited(String id, String type) =>
      favoriteKeys.contains('$id|$type');
  bool _isBookmarked(String id, String type) =>
      bookmarkKeys.contains('$id|$type');

  Future<void> _toggleFavorite(String id, String type) async {
    final key = '$id|$type';
    final was = _isFavorited(id, type);
    setState(() {
      if (was)
        favoriteKeys.remove(key);
      else
        favoriteKeys.add(key);
    });
    try {
      if (!was)
        await _service.addFavorite(id, type);
      else
        await _service.removeFavorite(id, type);
    } catch (e) {
      setState(() {
        if (!was)
          favoriteKeys.remove(key);
        else
          favoriteKeys.add(key);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Favorite update failed: $e')));
    }
  }

  Future<void> _toggleBookmark(String id, String type) async {
    final key = '$id|$type';
    final was = _isBookmarked(id, type);
    setState(() {
      if (was)
        bookmarkKeys.remove(key);
      else
        bookmarkKeys.add(key);
    });
    try {
      if (!was) {
        final note = await _askNoteDialog();
        await _service.addBookmark(id, type, note: note);
      } else {
        await _service.removeBookmark(id, type);
      }
    } catch (e) {
      setState(() {
        if (!was)
          bookmarkKeys.remove(key);
        else
          bookmarkKeys.add(key);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Bookmark update failed: $e')));
    }
  }

  Future<String?> _askNoteDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add a note (optional)"),
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

  List<Map<String, dynamic>> _filterListByTab(
    List<Map<String, dynamic>> items,
    String typeForKeys,
  ) {
    if (selectedTab == 'suggested') return items;
    if (selectedTab == 'favourites') {
      return items.where((e) {
        final id = e['id']?.toString() ?? '';
        return favoriteKeys.contains('$id|$typeForKeys');
      }).toList();
    }
    if (selectedTab == 'bookmarks') {
      return items.where((e) {
        final id = e['id']?.toString() ?? '';
        return bookmarkKeys.contains('$id|$typeForKeys');
      }).toList();
    }
    return items;
  }

  String _getSupabasePublicImageUrl(String path) {
    if (path.isEmpty) return '';
    return Supabase.instance.client.storage.from('books').getPublicUrl(path);
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/backgrounds/bg_resources.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(color: Colors.white.withValues(alpha: 0.2)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: const Color(0xFFDFF4E1),
                    ),
                    child: const Center(
                      child: Text(
                        'Welcome to the Psyche Archive!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D3B2E),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _PillTab(
                        label: 'Suggested',
                        selected: selectedTab == 'suggested',
                        onTap: () => setState(() => selectedTab = 'suggested'),
                      ),
                      _PillTab(
                        label: 'Favourites',
                        selected: selectedTab == 'favourites',
                        onTap: () => setState(() => selectedTab = 'favourites'),
                      ),
                      _PillTab(
                        label: 'Bookmarks',
                        selected: selectedTab == 'bookmarks',
                        onTap: () => setState(() => selectedTab = 'bookmarks'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _SectionHeader(
                    title: 'Recommended',
                    onSeeAll: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RecommendList()),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _recommendedFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 170,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return SizedBox(
                          height: 170,
                          child: Center(
                            child: Text(
                              'Error loading recommended: ${snapshot.error}',
                            ),
                          ),
                        );
                      }
                      final items = snapshot.data ?? [];
                      final displayItems = _filterListByTab(items, 'article');
                      if (displayItems.isEmpty) {
                        return SizedBox(
                          height: 170,
                          child: Center(
                            child: Text(
                              selectedTab == 'suggested'
                                  ? "No recommended items"
                                  : "No items found here",
                            ),
                          ),
                        );
                      }

                      return SizedBox(
                        height: 170,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: displayItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final rec = displayItems[i];
                            final id = rec['id']?.toString() ?? '';
                            final title = rec['title'] ?? '';
                            final imageUrl = rec['image_url'] as String? ?? '';
                            final content = rec['content'] ?? '';

                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RecommendDetail(
                                    title: title,
                                    content: content,
                                    imageUrl: imageUrl,
                                  ),
                                ),
                              ),
                              child: SizedBox(
                                width: 130,
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: const Color(0xFFDFF4E1),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x1A000000),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(16),
                                                ),
                                            child: imageUrl.isNotEmpty
                                                ? Image.network(
                                                    imageUrl,
                                                    width: double.infinity,
                                                    height: 100,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (_, __, ___) =>
                                                            Container(
                                                              height: 100,
                                                              color: Colors
                                                                  .grey
                                                                  .shade200,
                                                            ),
                                                  )
                                                : Container(
                                                    width: double.infinity,
                                                    height: 100,
                                                    color: Colors.grey.shade200,
                                                  ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: Text(
                                              title,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: GestureDetector(
                                        onTap: () {
                                          if (user == null) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'You must be logged in to favorite items.',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          _toggleFavorite(id, 'article');
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withAlpha(230),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            _isFavorited(id, 'article')
                                                ? Icons.star
                                                : Icons.star_border,
                                            size: 20,
                                            color: _isFavorited(id, 'article')
                                                ? Colors.amber
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 22),

                  _SectionHeader(
                    title: 'Articles For You',
                    onSeeAll: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ArticleScreen()),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _articlesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 180,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return SizedBox(
                          height: 180,
                          child: Center(
                            child: Text('Error: ${snapshot.error}'),
                          ),
                        );
                      }
                      final items = snapshot.data ?? [];
                      final displayItems = _filterListByTab(items, 'article');

                      if (displayItems.isEmpty) {
                        return SizedBox(
                          height: 180,
                          child: Center(
                            child: Text(
                              selectedTab == 'suggested'
                                  ? 'No articles yet'
                                  : 'No items found here',
                            ),
                          ),
                        );
                      }

                      return SizedBox(
                        height: 180,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: displayItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final a = displayItems[i];
                            final id = a['id']?.toString() ?? '';
                            final title = a['title'] ?? '';
                            final imageUrl = a['image_url'] as String? ?? '';
                            final content = a['content'] ?? '';

                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ArticleDetail(
                                    title: title,
                                    content: content,
                                    imageUrl: imageUrl,
                                  ),
                                ),
                              ),
                              child: SizedBox(
                                width: 130,
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: const Color(0xFFDFF4E1),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x1A000000),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(16),
                                                ),
                                            child: imageUrl.isNotEmpty
                                                ? Image.network(
                                                    imageUrl,
                                                    width: double.infinity,
                                                    height: 100,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (_, __, ___) =>
                                                            Container(
                                                              height: 100,
                                                              color: Colors
                                                                  .grey
                                                                  .shade200,
                                                            ),
                                                  )
                                                : Container(
                                                    width: double.infinity,
                                                    height: 100,
                                                    color: Colors.grey.shade200,
                                                  ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: Text(
                                              title,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: GestureDetector(
                                        onTap: () {
                                          if (user == null) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'You must be logged in to bookmark.',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          _toggleBookmark(id, 'article');
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withAlpha(230),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            _isBookmarked(id, 'article')
                                                ? Icons.bookmark
                                                : Icons.bookmark_border,
                                            size: 20,
                                            color: _isBookmarked(id, 'article')
                                                ? Colors.blue
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 22),

                  _SectionHeader(
                    title: 'Library',
                    onSeeAll: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LibraryScreen(title: 'Library'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _libraryFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return SizedBox(
                          height: 200,
                          child: Center(
                            child: Text(
                              'Error loading library: ${snapshot.error}',
                            ),
                          ),
                        );
                      }
                      final items = snapshot.data ?? [];
                      final displayItems = _filterListByTab(items, 'book');
                      if (displayItems.isEmpty) {
                        return SizedBox(
                          height: 200,
                          child: Center(
                            child: Text(
                              selectedTab == 'suggested'
                                  ? 'No books available'
                                  : 'No items found here',
                            ),
                          ),
                        );
                      }
                      return SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: displayItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final book = displayItems[i];
                            final id = book['id']?.toString() ?? '';
                            final title = book['title'] ?? 'Untitled';
                            final author = book['author'] ?? 'Unknown Author';
                            final imageUrl = book['image_url'] ?? '';
                            final description = book['description'] ?? '';
                            final pages = book['pages'] as int? ?? 0;
                            final publishedDate = book['published_date'] ?? '';
                            final pdfUrl = book['pdf_url'] as String?;

                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookDetail(
                                    title: title,
                                    author: author,
                                    imagePath: imageUrl,
                                    description: description,
                                    pages: pages,
                                    publishedDate: publishedDate,
                                    pdfUrl: pdfUrl,
                                  ),
                                ),
                              ),
                              child: Container(
                                width: 120,
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x1A000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          width: 120,
                                          height: 200,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                                width: 120,
                                                height: 200,
                                                color: Colors.grey.shade200,
                                                child: Center(
                                                  child: Text(
                                                    title,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                        )
                                      : Container(
                                          width: 120,
                                          height: 200,
                                          color: Colors.grey.shade200,
                                          child: Center(
                                            child: Text(
                                              title,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 3),
    );
  }
}

class _PillTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _PillTab({required this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF214033) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF214033)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: selected ? Colors.white : const Color(0xFF214033),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: const Text(
            'See all',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF214033),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
