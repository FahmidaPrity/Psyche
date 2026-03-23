import 'package:supabase_flutter/supabase_flutter.dart';

class ResourceService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchRecommended() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final res = await supabase
        .from('recommended_articles')
        .select()
        .order('created_at', ascending: false);
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchArticles() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final res = await supabase
        .from('articles')
        .select()
        .order('created_at', ascending: false);
    return (res as List).cast<Map<String, dynamic>>();
  }

  // --- helper ---
  Future<List<Map<String, dynamic>>> _selectWithFallback(
    String table,
    String primaryCols,
    String fallbackCols, {
    String? userId,
  }) async {
    try {
      final q = supabase.from(table).select(primaryCols);
      if (userId != null) q.eq('user_id', userId);
      final res = await q;
      return (res as List).cast<Map<String, dynamic>>();
    } catch (_) {
      final q2 = supabase.from(table).select(fallbackCols);
      if (userId != null) q2.eq('user_id', userId);
      final res2 = await q2;
      return (res2 as List).cast<Map<String, dynamic>>();
    }
  }

  // ---------------- LIBRARY BOOKS ----------------
  Future<List<Map<String, dynamic>>> fetchLibraryBooks() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    try {
      final res = await supabase
          .from('books')
          .select(
            'id, title, author, image_url, description, pages, published_date, pdf_url, created_at',
          )
          .order('created_at', ascending: false);
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching library books: $e');
      return [];
    }
  }

  // ---------------- FAVOURITES ----------------
  Future<Set<String>> fetchFavoriteKeys() async {
    final user = supabase.auth.currentUser;
    if (user == null) return {};
    final list = await _selectWithFallback(
      'favorites',
      'item_id,item_type',
      'resource_id,resource_type',
      userId: user.id,
    );
    final set = <String>{};
    for (final e in list) {
      final id = (e['item_id'] ?? e['resource_id'])?.toString();
      final t = (e['item_type'] ?? e['resource_type'])?.toString();
      if (id != null && t != null) set.add('$id|$t');
    }
    return set;
  }

  Future<void> addFavorite(String id, String type) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    try {
      await supabase.from('favorites').insert({
        'user_id': user.id,
        'item_id': id,
        'item_type': type,
      });
    } catch (_) {
      await supabase.from('favorites').insert({
        'user_id': user.id,
        'resource_id': id,
        'resource_type': type,
      });
    }
  }

  Future<void> removeFavorite(String id, String type) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    try {
      await supabase.from('favorites').delete().match({
        'user_id': user.id,
        'item_id': id,
        'item_type': type,
      });
    } catch (_) {
      await supabase.from('favorites').delete().match({
        'user_id': user.id,
        'resource_id': id,
        'resource_type': type,
      });
    }
  }

  // ---------------- BOOKMARKS ----------------
  Future<Set<String>> fetchBookmarkKeys() async {
    final user = supabase.auth.currentUser;
    if (user == null) return {};
    final list = await _selectWithFallback(
      'bookmarks',
      'item_id,item_type',
      'resource_id,resource_type',
      userId: user.id,
    );
    final set = <String>{};
    for (final e in list) {
      final id = (e['item_id'] ?? e['resource_id'])?.toString();
      final t = (e['item_type'] ?? e['resource_type'])?.toString();
      if (id != null && t != null) set.add('$id|$t');
    }
    return set;
  }

  Future<void> addBookmark(String id, String type, {String? note}) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    try {
      await supabase.from('bookmarks').insert({
        'user_id': user.id,
        'item_id': id,
        'item_type': type,
        'note': note,
      });
    } catch (_) {
      await supabase.from('bookmarks').insert({
        'user_id': user.id,
        'resource_id': id,
        'resource_type': type,
        'note': note,
      });
    }
  }

  Future<void> removeBookmark(String id, String type) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    try {
      await supabase.from('bookmarks').delete().match({
        'user_id': user.id,
        'item_id': id,
        'item_type': type,
      });
    } catch (_) {
      await supabase.from('bookmarks').delete().match({
        'user_id': user.id,
        'resource_id': id,
        'resource_type': type,
      });
    }
  }
}
