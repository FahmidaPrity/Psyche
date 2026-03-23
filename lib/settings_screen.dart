import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'widgets/bottom_navbar.dart';
import 'user/login_screen.dart';
import 'manual_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final user = Supabase.instance.client.auth.currentUser;
  String username = "";
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  Future<void> _fetchUsername() async {
    final response = await Supabase.instance.client
        .from('profiles')
        .select('username')
        .eq('id', user!.id)
        .maybeSingle();
    if (response != null && mounted) {
      setState(() {
        username = response['username'] ?? "User";
      });
    }
  }

  void _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _changeProfilePicture() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Change Profile Picture",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.teal),
              ),
              title: const Text("Take Photo"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library, color: Colors.teal),
              ),
              title: const Text("Choose from Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Colors.teal),
          ),
        );

        final file = File(image.path);
        final fileExt = image.path.split('.').last;
        final fileName =
            '${user!.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final filePath = fileName;

        await Supabase.instance.client.storage
            .from('avatars')
            .upload(filePath, file);

        final imageUrl = Supabase.instance.client.storage
            .from('avatars')
            .getPublicUrl(filePath);

        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: {'avatar_url': imageUrl}),
        );

        if (mounted) {
          Navigator.pop(context);
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profile picture updated successfully!"),
              backgroundColor: Colors.teal,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating profile picture: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BottomNavBar(currentIndex: 4),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            "assets/images/backgrounds/bg_settings.jpg",
            fit: BoxFit.cover,
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.25),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.4),
                          Colors.white.withOpacity(0.2),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.teal.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 65,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 62,
                                  backgroundImage: const AssetImage(
                                    "assets/images/others/default_avatar.jpg",
                                  ),
                                  foregroundImage:
                                      user?.userMetadata?['avatar_url'] != null
                                      ? NetworkImage(
                                          user!.userMetadata!['avatar_url'],
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _changeProfilePicture,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.teal, Color(0xFF00897B)],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.teal.withOpacity(0.5),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "@$username",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                blurRadius: 3,
                                color: Color.fromARGB(66, 0, 0, 0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user?.email ?? "",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.teal, Color(0xFF00897B)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Settings",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(221, 0, 0, 0),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _modernTile(
                    icon: Icons.person_outline,
                    title: "Account",
                    subtitle: "Coming Soon",
                    onTap: () {},
                    isComingSoon: true,
                  ),
                  _modernTile(
                    icon: Icons.notifications_outlined,
                    title: "Notifications",
                    subtitle: "Coming Soon",
                    onTap: () {},
                    isComingSoon: true,
                  ),
                  _modernTile(
                    icon: Icons.menu_book_outlined,
                    title: "App Manual",
                    subtitle: "Learn how to use the app",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManualScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  _modernTile(
                    icon: Icons.logout,
                    title: "Log out",
                    subtitle: "Sign out of your account",
                    onTap: _logout,
                    isLogout: true,
                  ),

                  const SizedBox(height: 40),

                  Column(
                    children: const [
                      Text(
                        "Made by Light & Love",
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                          shadows: [
                            Shadow(
                              blurRadius: 2,
                              color: Color.fromARGB(66, 0, 0, 0),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Version: 1.0.0",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(136, 0, 0, 0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
    bool isComingSoon = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLogout
              ? [Colors.red.withOpacity(0.15), Colors.red.withOpacity(0.25)]
              : [
                  Colors.white.withOpacity(0.35),
                  Colors.white.withOpacity(0.25),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isComingSoon ? null : onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isLogout
                              ? [
                                  const Color.fromARGB(255, 185, 47, 37),
                                  const Color.fromARGB(255, 104, 24, 18),
                                ]
                              : [Colors.teal, const Color(0xFF00897B)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (isLogout ? Colors.red : Colors.teal)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isLogout
                                  ? const Color.fromARGB(255, 185, 47, 37)
                                  : const Color.fromARGB(221, 0, 0, 0),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isComingSoon
                                        ? Colors.orange
                                        : Colors.black.withOpacity(0.5),
                                    fontStyle: isComingSoon
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                ),
                              ),
                              if (isComingSoon)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "Soon",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
