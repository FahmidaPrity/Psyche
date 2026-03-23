import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home_screen.dart';
import 'mood_four.dart';

class MoodThreeScreen extends StatefulWidget {
  final String checkInId;
  final List<String> selectedReasons;

  const MoodThreeScreen({
    super.key,
    required this.checkInId,
    required this.selectedReasons,
  });

  @override
  State<MoodThreeScreen> createState() => _MoodThreeScreenState();
}

class _MoodThreeScreenState extends State<MoodThreeScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  final Set<String> _selectedFeelings = {};
  bool _isLoading = false;

  final List<Map<String, String>> feelings = [
    {"image": "assets/images/mood/calm.gif", "label": "Calm"},
    {"image": "assets/images/mood/low.gif", "label": "Low"},
    {"image": "assets/images/mood/suicidal.gif", "label": "Suicidal"},
    {"image": "assets/images/mood/drained.gif", "label": "Drained"},
    {"image": "assets/images/mood/anxious.gif", "label": "Anxious"},
    {"image": "assets/images/mood/frustrated.gif", "label": "Frustrated"},
  ];

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  Future<void> _saveFeelingsToCheckIn() async {
    if (_selectedFeelings.isEmpty) return;
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showErrorSnackBar('Please log in to continue');
      return;
    }
    try {
      await Supabase.instance.client
          .from('moods')
          .update({
            'feelings': _selectedFeelings.toList(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.checkInId)
          .eq('user_id', user.id);
    } catch (e) {
      _showErrorSnackBar('Error saving your feelings, try again.');
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (!mounted) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => MoodFourScreen(
          checkInId: widget.checkInId,
          reasons: widget.selectedReasons,
          feelings: _selectedFeelings.toList(),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color.fromARGB(255, 239, 83, 80),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _feelingBox(String path, String label, int index) {
    final animation = CurvedAnimation(
      parent: _mainController,
      curve: Interval(
        (index * 0.1).clamp(0.0, 1.0),
        1.0,
        curve: Curves.easeOutBack,
      ),
    );
    final isSelected = _selectedFeelings.contains(label);

    return ScaleTransition(
      scale: animation,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFeelings
              ..clear()
              ..add(label);
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color.fromARGB(255, 24, 41, 25)
                      : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  path,
                  height: 72,
                  width: 72,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? const Color.fromARGB(255, 24, 41, 25)
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundShadowImage(String path, {double size = 95}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 65, 66, 66).withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(2, 4),
              ),
            ],
          ),
        ),
        Image.asset(path, height: size, width: size, fit: BoxFit.cover),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/backgrounds/bg_mood.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(
            color: Colors.white.withOpacity(0.1),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 40),
                        ScaleTransition(
                          scale: CurvedAnimation(
                            parent: _mainController,
                            curve: const Interval(
                              0.0,
                              0.5,
                              curve: Curves.elasticOut,
                            ),
                          ),
                          child: _roundShadowImage(
                            "assets/images/mood/mood_3.png",
                            size: 95,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.home,
                            size: 30,
                            color: Colors.black87,
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomeScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _mainController,
                        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
                      ),
                      child: const Text(
                        "…and which feelings are you\n deeply relating to?",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 22),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 22,
                      children: List.generate(feelings.length, (index) {
                        return _feelingBox(
                          feelings[index]["image"]!,
                          feelings[index]["label"]!,
                          index,
                        );
                      }),
                    ),

                    const SizedBox(height: 28),

                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _mainController,
                        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            24,
                            41,
                            25,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 65,
                            vertical: 14,
                          ),
                          elevation: 7,
                          shadowColor: Colors.black.withOpacity(0.25),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isLoading || _selectedFeelings.isEmpty
                            ? null
                            : _saveFeelingsToCheckIn,
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
                                "Continue",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color.fromARGB(255, 242, 250, 242),
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 40),
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
