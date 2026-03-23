import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'user/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));

    _positionAnimation = Tween<double>(begin: 0.4, end: 0.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();

    Timer(const Duration(seconds: 4), _goNext);
  }

  void _goNext() {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // User is already logged in → go to Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // No active session → go to Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/backgrounds/bg_splash.jpg',
            fit: BoxFit.cover,
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              color: const Color.fromARGB(255, 246, 255, 251).withOpacity(0.05),
            ),
          ),
          AnimatedBuilder(
            animation: _positionAnimation,
            builder: (context, child) {
              return Positioned(
                top: screenHeight * _positionAnimation.value,
                left: 0,
                right: 0,
                child: Center(
                  child: Image.asset(
                    'assets/images/icons/psyche_logo.png',
                    width: screenHeight * 0.25,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
