import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home_screen.dart';
import 'mood_two.dart';

class MoodOneScreen extends StatefulWidget {
  const MoodOneScreen({super.key});

  @override
  State<MoodOneScreen> createState() => _MoodOneScreenState();
}

class _MoodOneScreenState extends State<MoodOneScreen>
    with TickerProviderStateMixin {
  double _sliderValue = 2;
  bool _isLoading = false;

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;

  final List<String> moodImages = [
    "assets/images/mood/one.png",
    "assets/images/mood/two.png",
    "assets/images/mood/three.png",
    "assets/images/mood/four.png",
    "assets/images/mood/five.png",
  ];

  final List<String> moodLabels = [
    "Angry",
    "Worried",
    "Unsure",
    "Tired",
    "Happy",
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeController.forward();
    _scaleController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<String?> _startMoodCheckIn() async {
    if (_isLoading) return null;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        _showErrorSnackBar('Please log in to continue');
        return null;
      }

      final response = await supabase
          .from('moods')
          .insert({
            'user_id': user.id,
            'mood_level': _sliderValue.toInt() + 1,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'status': 'in_progress',
          })
          .select('id')
          .single();

      return response['id'] as String?;
    } catch (e) {
      debugPrint("Error starting mood check-in: $e");
      _showErrorSnackBar('Failed to start mood check-in. Please try again.');
      return null;
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
      ),
    );
  }

  Widget _buildCustomShadowImage(String path, {double size = 70}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.20),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(path, width: size, height: size, fit: BoxFit.cover),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

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
            child: Container(color: Colors.white.withOpacity(0.08)),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05,
                        vertical: isSmallScreen ? 8 : 16,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildHeader(screenWidth, isSmallScreen),
                          _buildContent(
                            screenHeight,
                            screenWidth,
                            isSmallScreen,
                          ),
                          _buildContinueButton(screenWidth),
                        ],
                      ),
                    ),
                  ),
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
              parent: _slideController,
              curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
            ),
          ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40),
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _scaleController,
              curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
            ),
            child: _buildCustomShadowImage(
              "assets/images/mood/mood_1.png",
              size: isSmallScreen ? 90 : 110,
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
              color: Color.fromARGB(197, 0, 0, 0),
            ),
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    double screenHeight,
    double screenWidth,
    bool isSmallScreen,
  ) {
    return FadeTransition(
      opacity: _fadeController,
      child: Column(
        children: [
          _buildTitleSection(isSmallScreen),
          SizedBox(height: isSmallScreen ? 20 : 30),
          _buildMoodSelection(screenWidth, isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildTitleSection(bool isSmallScreen) {
    return Column(
      children: [
        Text(
          "How are you feeling today?",
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Emotions are meant to be felt, not hidden or ignored. "
            "Whatever you're going through, remember YOU'RE STRONG.",
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: const Color.fromARGB(221, 0, 0, 0),
              height: 1.4,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildMoodSelection(double screenWidth, bool isSmallScreen) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _scaleController,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
      child: Column(
        children: [
          _buildCustomShadowImage(
            moodImages[_sliderValue.toInt()],
            size: isSmallScreen ? 70 : 85,
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            moodLabels[_sliderValue.toInt()],
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: const Color.fromARGB(255, 42, 95, 44),
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color.fromARGB(255, 42, 95, 44),
              inactiveTrackColor: Colors.grey.shade300,
              thumbColor: const Color.fromARGB(255, 24, 41, 25),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              trackHeight: 4,
            ),
            child: Slider(
              value: _sliderValue,
              min: 0,
              max: 4,
              divisions: 4,
              onChanged: (value) {
                setState(() => _sliderValue = value);
              },
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(moodImages.length, (index) {
              final isSelected = index == _sliderValue.toInt();
              return GestureDetector(
                onTap: () => setState(() => _sliderValue = index.toDouble()),
                child: AnimatedScale(
                  scale: isSelected ? 1.1 : 0.9,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? Border.all(
                              color: const Color.fromARGB(255, 42, 95, 44),
                              width: 2,
                            )
                          : null,
                    ),
                    child: _buildCustomShadowImage(
                      moodImages[index],
                      size: isSmallScreen ? 28 : 35,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(double screenWidth) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _slideController,
              curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
            ),
          ),
      child: Container(
        width: screenWidth * 0.7,
        height: 52,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 24, 41, 25).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 24, 41, 25),
            foregroundColor: const Color.fromARGB(255, 242, 250, 242),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: _isLoading ? null : _handleContinue,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  "Continue",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  void _handleContinue() async {
    final checkInId = await _startMoodCheckIn();
    if (checkInId != null && mounted) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              MoodTwoScreen(checkInId: checkInId),
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
  }
}
