import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mood/mood_screen.dart';
import 'feed/feed_screen.dart';
import 'article/article_screen.dart';
import 'library/library_screen.dart';
import 'widgets/bottom_navbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final List<String> quotes = [
    "Healing takes time, and asking for help is a courageous step.",
    "Self-care is how you take your power back.",
    "Your present circumstances don't determine where you can go; they determine where you start.",
    "You don't have to control your thoughts. Just stop letting them control you.",
    "What mental health needs is more sunlight and more unashamed conversation.",
    "Small steps every day lead to big changes.",
    "It's okay to not be okay.",
    "Rest is productive too.",
    "You are stronger than you think.",
    "Progress, not perfection.",
    "Your mind matters.",
    "Peace begins with a deep breath.",
    "Be gentle with yourself, you're doing your best.",
    "Growth is often uncomfortable but worth it.",
    "Your story isn't over yet.",
    "Kindness to yourself is never wasted.",
    "Let today be the start of something new.",
    "Choose hope every single day.",
    "You're not alone in this journey.",
  ];

  int _currentQuoteIndex = 0;
  late Timer _timer;

  late AnimationController _boxController;
  late List<Animation<Offset>> _boxAnimations;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 7), (timer) {
      setState(() {
        _currentQuoteIndex = (_currentQuoteIndex + 1) % quotes.length;
      });
    });

    _boxController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _boxAnimations = List.generate(4, (index) {
      final start = 0.2 * index;
      final end = (0.6 + 0.2 * index).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _boxController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _boxController.forward();
  }

  @override
  void dispose() {
    _timer.cancel();
    _boxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Container(
            height: size.height,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/backgrounds/bg_home.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
              child: Container(
                height: size.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color.fromARGB(255, 255, 255, 255).withOpacity(0.4),
                      Colors.green.shade50.withOpacity(0.3),
                      const Color.fromARGB(255, 255, 255, 255).withOpacity(0.2),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildTopSection(),
                  const SizedBox(height: 10),
                  _buildQuoteSection(),
                  const SizedBox(height: 30),
                  _buildFeatureBoxes(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildTopSection() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 25,
            offset: const Offset(0, 12),
            spreadRadius: 3,
          ),
        ],
      ),
      child: ClipPath(
        clipper: BottomCurveClipper(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 260,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    "assets/images/backgrounds/bg_home_top.jpg",
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            ClipPath(
              clipper: BottomCurveClipper(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                child: Container(
                  height: 260,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color.fromARGB(
                          255,
                          255,
                          255,
                          255,
                        ).withOpacity(0.05),
                        const Color.fromARGB(255, 46, 125, 50).withOpacity(0.2),
                        const Color.fromARGB(255, 67, 160, 71).withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Let's step into the dream",
                  style: GoogleFonts.loveLight(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 255, 255, 255),
                    shadows: [
                      Shadow(
                        blurRadius: 6,
                        color: const Color.fromARGB(
                          255,
                          0,
                          0,
                          0,
                        ).withOpacity(0.4),
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Image.asset("assets/images/icons/top.gif", height: 100),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color.fromARGB(255, 255, 255, 255).withOpacity(0.4),
            const Color.fromARGB(255, 232, 245, 233).withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade200.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.format_quote, color: Colors.green.shade600, size: 30),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(seconds: 1),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              quotes[_currentQuoteIndex],
              key: ValueKey<int>(_currentQuoteIndex),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w400,
                color: Colors.green.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBoxes() {
    final boxes = [
      EnhancedFeatureBox(
        icon: "assets/images/icons/mood.gif",
        title: "Echoes of Your Heart",
        subtitle: "Track and reflect on your emotions daily",
        gradient: [Colors.green.shade400, Colors.green.shade600],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MoodScreen()),
        ),
      ),
      EnhancedFeatureBox(
        icon: "assets/images/icons/feed.gif",
        title: "Gather in the Circle",
        subtitle: "Connect with a supportive community",
        gradient: [Colors.teal.shade400, Colors.teal.shade600],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FeedScreen()),
        ),
      ),
      EnhancedFeatureBox(
        icon: "assets/images/icons/article.gif",
        title: "Articles",
        subtitle: "Explore various articles for mental wellness",
        gradient: [Colors.lightGreen.shade600, Colors.green.shade800],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ArticleScreen()),
        ),
      ),
      EnhancedFeatureBox(
        icon: "assets/images/icons/library.gif",
        title: "Library",
        subtitle: "Discover inspiring mental health resources",
        gradient: [Colors.lime.shade600, Colors.green.shade700],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LibraryScreen(title: "Minilib"),
          ),
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(boxes.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: SlideTransition(
              position: _boxAnimations[i],
              child: boxes[i],
            ),
          );
        }),
      ),
    );
  }
}

class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class EnhancedFeatureBox extends StatefulWidget {
  final String icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const EnhancedFeatureBox({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<EnhancedFeatureBox> createState() => _EnhancedFeatureBoxState();
}

class _EnhancedFeatureBoxState extends State<EnhancedFeatureBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _animationController.forward(),
            onTapUp: (_) {
              _animationController.reverse();
              widget.onTap();
            },
            onTapCancel: () => _animationController.reverse(),
            child: Container(
              margin: const EdgeInsets.only(bottom: 0),
              width: double.infinity,
              height: 200,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color.fromARGB(
                            255,
                            255,
                            255,
                            255,
                          ).withOpacity(0.5),
                          const Color.fromARGB(
                            255,
                            255,
                            255,
                            255,
                          ).withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color.fromARGB(
                          255,
                          255,
                          255,
                          255,
                        ).withOpacity(0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.gradient[1].withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: const Color.fromARGB(
                            255,
                            255,
                            255,
                            255,
                          ).withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 65, 20, 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.subtitle,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.green.shade700.withOpacity(0.8),
                                  height: 1.3,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -35,
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.gradient[1].withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(widget.icon, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
