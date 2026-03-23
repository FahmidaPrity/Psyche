import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/bottom_navbar.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isAnonymous = false;
  String _searchQuery = "";
  File? _selectedImage;
  bool _showSearch = false;

  Set<dynamic> _likedPosts = {};

  final supabase = Supabase.instance.client;

  // Random names for anonymous posts
  final List<String> _randomAdjectives = [
    'Silent',
    'Mysterious',
    'Hidden',
    'Secret',
    'Unknown',
    'Quiet',
    'Shy',
    'Bold',
    'Brave',
    'Swift',
    'Clever',
    'Wise',
    'Kind',
    'Gentle',
    'Fierce',
    'Bright',
    'Dark',
    'Golden',
    'Silver',
    'Crystal',
    'Shadow',
    'Storm',
  ];

  final List<String> _randomNouns = [
    'Wolf',
    'Eagle',
    'Fox',
    'Bear',
    'Lion',
    'Tiger',
    'Dragon',
    'Phoenix',
    'Star',
    'Moon',
    'Sun',
    'River',
    'Mountain',
    'Ocean',
    'Forest',
    'Wind',
    'Thunder',
    'Lightning',
    'Fire',
    'Ice',
    'Stone',
    'Dream',
    'Soul',
    'Spirit',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserLikes();
  }

  // Load user's liked posts
  Future<void> _loadUserLikes() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('likes')
          .select('post_id')
          .eq('user_id', user.id);

      setState(() {
        _likedPosts = response
            .map<String>((like) => like['post_id'] as String)
            .toSet();
      });
    } catch (e) {
      print('Error loading likes: $e');
    }
  }

  String _generateRandomName() {
    final random = Random();
    final adjective =
        _randomAdjectives[random.nextInt(_randomAdjectives.length)];
    final noun = _randomNouns[random.nextInt(_randomNouns.length)];
    final number = random.nextInt(999) + 1;
    return '$adjective$noun$number';
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error picking image')));
      }
    }
  }

  Future<void> _addPost() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      if (_postController.text.trim().isEmpty && _selectedImage == null) return;

      String? imageUrl;

      if (_selectedImage != null) {
        final fileName =
            "${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg";
        await supabase.storage
            .from("post_images")
            .upload(fileName, _selectedImage!);
        imageUrl = supabase.storage.from("post_images").getPublicUrl(fileName);
      }

      String? anonymousName;
      if (_isAnonymous) {
        anonymousName = _generateRandomName();
      }

      await supabase.from('posts').insert({
        'text': _postController.text.trim(),
        'image_url': imageUrl,
        'uid': user.id,
        'user_id': user.id,
        'is_anonymous': _isAnonymous,
        'anonymous_name': anonymousName,
      });

      _postController.clear();
      setState(() {
        _selectedImage = null;
        _isAnonymous = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post added successfully!')),
        );
      }
    } catch (e) {
      print('Error adding post: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error adding post')));
      }
    }
  }

  Future<void> _editPost(dynamic postId, String oldText) async {
    final controller = TextEditingController(text: oldText);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Post"),
        content: TextField(
          controller: controller,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: "Edit your post...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                if (controller.text.trim().isNotEmpty) {
                  await supabase
                      .from('posts')
                      .update({'text': controller.text.trim()})
                      .eq('id', postId);
                  Navigator.pop(context);
                  setState(() {});
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Post updated successfully!'),
                      ),
                    );
                  }
                }
              } catch (e) {
                print('Error editing post: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error editing post')),
                  );
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _addComment(dynamic postId, String text) async {
    try {
      final user = supabase.auth.currentUser;
      if (text.trim().isEmpty || user == null) return;

      final profile = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .single();

      String displayName = profile['full_name'] ?? 'User';

      await supabase.from('comments').insert({
        'post_id': postId,
        'text': text.trim(),
        'username': displayName,
        'uid': user.id,
      });
      setState(() {});
    } catch (e) {
      print('Error adding comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error adding comment')));
      }
    }
  }

  void _showComments(dynamic postId) {
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                const Text(
                  "Comments",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Divider(),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: supabase
                        .from('comments')
                        .select()
                        .eq('post_id', postId)
                        .order('created_at', ascending: false),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return const Center(
                          child: Text("Error loading comments"),
                        );
                      }

                      final comments = snapshot.data ?? [];
                      if (comments.isEmpty) {
                        return const Center(child: Text("No comments yet"));
                      }
                      return ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final data = comments[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color.fromARGB(
                                255,
                                16,
                                100,
                                44,
                              ),
                              child: Text(
                                (data['username'] ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              data['username'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(data['text'] ?? ''),
                          );
                        },
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: const InputDecoration(
                          hintText: "Write a comment...",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        _addComment(postId, commentController.text);
                        commentController.clear();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deletePost(dynamic postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color.fromARGB(255, 218, 48, 36)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await supabase.from('posts').delete().eq('id', postId);
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully!')),
          );
        }
      } catch (e) {
        print('Error deleting post: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Error deleting post')));
        }
      }
    }
  }

  // Like/unlike functionality
  Future<void> _toggleLike(dynamic postId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final isLiked = _likedPosts.contains(postId);

      if (isLiked) {
        // Unlike the post
        await supabase
            .from('likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', user.id);

        setState(() {
          _likedPosts.remove(postId);
        });
      } else {
        // Like the post
        await supabase.from('likes').insert({
          'post_id': postId,
          'user_id': user.id,
        });

        setState(() {
          _likedPosts.add(postId);
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error updating like')));
      }
    }
  }

  String _formatTime(String? timestamp) {
    try {
      if (timestamp == null) return '';

      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'now';
      }
    } catch (e) {
      print('Error formatting time: $e');
      return '';
    }
  }

  Widget _buildPostCard(Map<String, dynamic> postData) {
    final user = supabase.auth.currentUser;
    final isOwner = user != null && user.id == postData['uid'];
    final isLiked = _likedPosts.contains(postData['id']);

    String displayName;
    String username;

    if (postData['is_anonymous'] == true) {
      displayName = 'Anonymous';
      username = '@${postData['anonymous_name'] ?? 'unknown'}';
    } else {
      displayName = postData['profiles']?['full_name'] ?? 'User';
      username = '@${postData['profiles']?['username'] ?? 'user'}';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: postData['is_anonymous'] == true
                      ? const Color.fromARGB(255, 117, 117, 117)
                      : const Color.fromARGB(255, 23, 117, 54),
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        username,
                        style: TextStyle(
                          color: const Color.fromARGB(255, 117, 117, 117),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatTime(postData['created_at']),
                  style: TextStyle(
                    color: const Color.fromARGB(255, 117, 117, 117),
                    fontSize: 11,
                  ),
                ),
                if (isOwner) ...[
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deletePost(postData['id']);
                      } else if (value == 'edit') {
                        _editPost(postData['id'], postData['text'] ?? '');
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text("Edit"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              size: 16,
                              color: Color.fromARGB(255, 172, 39, 29),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Delete",
                              style: TextStyle(
                                color: Color.fromARGB(255, 190, 42, 31),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            if ((postData['text'] ?? "").isNotEmpty)
              Text(postData['text'], style: const TextStyle(fontSize: 14)),

            if ((postData['text'] ?? "").isNotEmpty &&
                postData['image_url'] != null)
              const SizedBox(height: 12),

            if (postData['image_url'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  postData['image_url'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 224, 224, 224),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.grey, size: 32),
                            SizedBox(height: 8),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showComments(postData['id']),
                  icon: const Icon(Icons.comment, size: 16),
                  label: const Text("Comment"),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _toggleLike(postData['id']),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        isLiked
                            ? 'assets/images/icons/liked.png'
                            : 'assets/images/icons/like.png',
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 4),
                      const Text("Like"),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    "Psyche",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(221, 0, 0, 0),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      setState(() => _showSearch = !_showSearch);
                    },
                  ),
                ],
              ),
            ),

            if (_showSearch)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search posts...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim().toLowerCase());
                  },
                ),
              ),

            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _postController,
                          decoration: InputDecoration(
                            hintText: "What's on your mind?",
                            filled: true,
                            fillColor: const Color.fromARGB(255, 245, 245, 245),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.image,
                          color: Color.fromARGB(255, 28, 100, 21),
                        ),
                        onPressed: _pickImage,
                        tooltip: 'Add Image',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Color.fromARGB(255, 13, 77, 21),
                        ),
                        onPressed: _addPost,
                        tooltip: 'Post',
                      ),
                    ],
                  ),
                  if (_selectedImage != null) ...[
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: const Color.fromARGB(136, 0, 0, 0),
                            radius: 16,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                              onPressed: () {
                                setState(() => _selectedImage = null);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  Row(
                    children: [
                      Checkbox(
                        value: _isAnonymous,
                        onChanged: (val) {
                          setState(() => _isAnonymous = val ?? false);
                        },
                        activeColor: const Color.fromARGB(255, 28, 102, 21),
                      ),
                      const Text("Post anonymously"),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: supabase
                    .from('posts')
                    .select('''
                      *,
                      profiles!posts_user_id_fkey (
                        full_name,
                        username
                      )
                    ''')
                    .order('created_at', ascending: false),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    print('Error loading posts: ${snapshot.error}');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error,
                            size: 48,
                            color: Color.fromARGB(255, 158, 158, 158),
                          ),
                          const SizedBox(height: 16),
                          const Text("Error loading posts"),
                          TextButton(
                            onPressed: () => setState(() {}),
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.post_add,
                            size: 48,
                            color: Color.fromARGB(255, 158, 158, 158),
                          ),
                          SizedBox(height: 16),
                          Text("No posts yet", style: TextStyle(fontSize: 18)),
                          SizedBox(height: 8),
                          Text(
                            "Be the first to share something!",
                            style: TextStyle(
                              color: Color.fromARGB(255, 158, 158, 158),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final posts = snapshot.data!.where((post) {
                    if (_searchQuery.isEmpty) return true;

                    final text = (post['text'] ?? "").toString().toLowerCase();
                    final fullName = (post['profiles']?['full_name'] ?? "")
                        .toString()
                        .toLowerCase();
                    final username = (post['profiles']?['username'] ?? "")
                        .toString()
                        .toLowerCase();
                    final anonymousName = (post['anonymous_name'] ?? "")
                        .toString()
                        .toLowerCase();

                    return text.contains(_searchQuery) ||
                        fullName.contains(_searchQuery) ||
                        username.contains(_searchQuery) ||
                        anonymousName.contains(_searchQuery);
                  }).toList();

                  if (posts.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Color.fromARGB(255, 158, 158, 158),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "No posts found",
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Try a different search term",
                            style: TextStyle(
                              color: Color.fromARGB(255, 158, 158, 158),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      return _buildPostCard(posts[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  @override
  void dispose() {
    _postController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
