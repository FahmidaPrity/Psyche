import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home_screen.dart';
import 'mood_three.dart';

class MoodTwoScreen extends StatefulWidget {
  final String checkInId;

  const MoodTwoScreen({super.key, required this.checkInId});

  @override
  State<MoodTwoScreen> createState() => _MoodTwoScreenState();
}

class _MoodTwoScreenState extends State<MoodTwoScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _buttonController;

  final Set<String> _selectedReasons = {};
  bool _isLoading = false;

  final List<Map<String, dynamic>> reasonOptions = [
    {"icon": Icons.work_rounded, "label": "Work", "color": Colors.blue},
    {"icon": Icons.home_rounded, "label": "Family", "color": Colors.orange},
    {"icon": Icons.people_rounded, "label": "Friends", "color": Colors.green},
    {"icon": Icons.school_rounded, "label": "Studies", "color": Colors.purple},
    {
      "icon": Icons.favorite_rounded,
      "label": "Relationship",
      "color": const Color.fromARGB(255, 199, 38, 91),
    },
    {
      "icon": Icons.flight_takeoff_rounded,
      "label": "Travel",
      "color": Colors.teal,
    },
    {"icon": Icons.restaurant_rounded, "label": "Food", "color": Colors.amber},
    {
      "icon": Icons.fitness_center_rounded,
      "label": "Exercise",
      "color": const Color.fromARGB(255, 196, 52, 41),
    },
    {
      "icon": Icons.health_and_safety_rounded,
      "label": "Health",
      "color": Colors.indigo,
    },
    {
      "icon": Icons.attach_money_rounded,
      "label": "Money",
      "color": Colors.brown,
    },
    {"icon": Icons.pets_rounded, "label": "Pets", "color": Colors.lime},
    {"icon": Icons.music_note_rounded, "label": "Music", "color": Colors.cyan},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _mainController.forward();
    _buttonController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _saveReasonsAndContinue() async {
    if (_selectedReasons.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        _showErrorSnackBar('Authentication error. Please log in again.');
        return;
      }

      await supabase
          .from('moods')
          .update({
            'reasons': _selectedReasons.toList(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.checkInId);

      if (!mounted) return;

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              MoodThreeScreen(
                checkInId: widget.checkInId,
                selectedReasons: _selectedReasons.toList(),
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
    } catch (e) {
      debugPrint('Error saving reasons: $e');
      _showErrorSnackBar('Failed to save your selections. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color.fromARGB(255, 239, 83, 80),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 16,
          right: 16,
        ),
      ),
    );
  }

  Widget _buildCustomShadowImage(String path, {double size = 95}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(path, width: size, height: size, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildReasonOption(Map<String, dynamic> option, int index) {
    final animation = CurvedAnimation(
      parent: _mainController,
      curve: Interval(
        (index * 0.05).clamp(0.0, 0.8),
        1.0,
        curve: Curves.easeOutBack,
      ),
    );

    final isSelected = _selectedReasons.contains(option["label"]);
    final optionColor = option["color"] as Color;

    return ScaleTransition(
      scale: animation,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedReasons.remove(option["label"]);
            } else {
              _selectedReasons.add(option["label"]);
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected
                ? optionColor.withOpacity(0.9)
                : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? optionColor : const Color.fromARGB(255, 224, 224, 224),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? optionColor.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                option["icon"],
                size: 28,
                color: isSelected ? Colors.white : optionColor,
              ),
              const SizedBox(height: 8),
              Text(
                option["label"],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : const Color.fromARGB(221, 0, 0, 0),
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final crossAxisCount = screenWidth > 600 ? 4 : 3;

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
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(color: Colors.white.withOpacity(0.1)),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    _buildHeader(screenWidth, isSmallScreen),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            _buildTitle(isSmallScreen),
                            SizedBox(height: isSmallScreen ? 16 : 24),
                            _buildReasonsGrid(crossAxisCount, isSmallScreen),
                            SizedBox(height: isSmallScreen ? 24 : 32),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomSection(screenWidth, isSmallScreen),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double screenWidth, bool isSmallScreen) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _mainController,
              curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
            ),
          ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: isSmallScreen ? 8 : 16,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 40),
            ScaleTransition(
              scale: CurvedAnimation(
                parent: _mainController,
                curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
              ),
              child: _buildCustomShadowImage(
                "assets/images/mood/mood_2.png",
                size: isSmallScreen ? 80 : 95,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              ),
              icon: const Icon(
                Icons.home_rounded,
                size: 28,
                color: Color.fromARGB(195, 0, 0, 0),
              ),
              splashRadius: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(bool isSmallScreen) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
      child: Column(
        children: [
          Text(
            "What's making you\nfeel this way?",
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(221, 0, 0, 0),
              letterSpacing: 0.5,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          if (_selectedReasons.isNotEmpty) ...[
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              "${_selectedReasons.length} selected",
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: const Color.fromARGB(255, 42, 95, 44),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReasonsGrid(int crossAxisCount, bool isSmallScreen) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: isSmallScreen ? 12 : 16,
        mainAxisSpacing: isSmallScreen ? 12 : 16,
        childAspectRatio: 1.0,
      ),
      itemCount: reasonOptions.length,
      itemBuilder: (context, index) {
        return _buildReasonOption(reasonOptions[index], index);
      },
    );
  }

  Widget _buildBottomSection(double screenWidth, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.05,
        isSmallScreen ? 12 : 16,
        screenWidth * 0.05,
        MediaQuery.of(context).padding.bottom + (isSmallScreen ? 12 : 16),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.white.withOpacity(0.1)],
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _buttonController,
                curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
              ),
            ),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 24, 41, 25).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedReasons.isEmpty
                  ? const Color.fromARGB(255, 189, 189, 189)
                  : const Color.fromARGB(255, 24, 41, 25),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _selectedReasons.isEmpty || _isLoading
                ? null
                : _saveReasonsAndContinue,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _selectedReasons.isEmpty
                        ? "Select at least one reason"
                        : "Continue",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
