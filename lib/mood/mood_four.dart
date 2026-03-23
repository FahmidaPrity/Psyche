import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home_screen.dart';
import 'mood_screen.dart';

class MoodFourScreen extends StatefulWidget {
  final String checkInId;
  final List<String> reasons;
  final List<String> feelings;

  const MoodFourScreen({
    super.key,
    required this.checkInId,
    required this.reasons,
    required this.feelings,
  });

  @override
  State<MoodFourScreen> createState() => _MoodFourScreenState();
}

class _MoodFourScreenState extends State<MoodFourScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _isLoading = false;
  bool _showDemoNote = false;

  Future<void> _completeCheckIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client
          .from('moods')
          .update({
            'note_title': _titleController.text.trim(),
            'note_description': _descController.text.trim(),
            'status': 'completed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.checkInId)
          .eq('user_id', user.id);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MoodScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error completing check-in. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formattedNow() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return "${monthNames[now.month - 1]} ${now.day}, $hour:${now.minute.toString().padLeft(2, '0')} $ampm";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/backgrounds/bg_mood.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(color: Colors.white.withOpacity(0.05)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.home,
                            color: Color.fromARGB(221, 0, 0, 0),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomeScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 90,
                              offset: const Offset(2, 4),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          "assets/images/mood/mood_4.png",
                          height: 100,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _formattedNow(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildGlassyBox(
                      child: Row(
                        children: [
                          const Text(
                            "Reasons: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              widget.reasons.join(", "),
                              style: const TextStyle(fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildGlassyBox(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Feelings: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              widget.feelings.join(", "),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildGlassyBox(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Title",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _titleController,
                            maxLines: 1,
                            style: const TextStyle(
                              color: Color.fromARGB(221, 0, 0, 0),
                            ),
                            decoration: InputDecoration(
                              hintText: "Enter a short title...",
                              hintStyle: const TextStyle(
                                color: Color.fromARGB(137, 0, 0, 0),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Description",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _descController,
                            maxLines: 4,
                            style: const TextStyle(
                              color: Color.fromARGB(221, 0, 0, 0),
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  "Write something your heart feels like saying...",
                              hintStyle: const TextStyle(
                                color: Color.fromARGB(137, 0, 0, 0),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showDemoNote = !_showDemoNote;
                        });
                      },
                      child: Text(
                        _showDemoNote
                            ? "Hide demo note"
                            : "Confused what to write? Let's see...",
                        style: const TextStyle(
                          color: Colors.black87,
                          fontStyle: FontStyle.italic,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: _showDemoNote
                          ? _buildDemoNote()
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 14,
                        ),
                        backgroundColor: Colors.green.shade800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                      ),
                      onPressed: _isLoading ? null : _completeCheckIn,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              "Complete Check-In",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoNote() {
    return Padding(
      key: const ValueKey("demo_note"),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Example Note (Optional)",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Title: A Breath of Calm\n\n"
                  "Description: Today, I felt overwhelmed but found peace in the small things, "
                  "a cup of tea, the sound of rain, and forgiving myself for not being perfect. "
                  "This space reminds me that my feelings are valid, and healing takes time.",
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassyBox({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
