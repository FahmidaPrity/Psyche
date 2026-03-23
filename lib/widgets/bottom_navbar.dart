import 'dart:ui';
import 'package:flutter/material.dart';
import '../home_screen.dart';
import '../mood/mood_screen.dart';
import '../feed/feed_screen.dart';
import '../resources/resource_screen.dart';
import '../settings_screen.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  const BottomNavBar({Key? key, required this.currentIndex}) : super(key: key);

  void _onItemTapped(BuildContext context, int index) {
    Widget destination;
    switch (index) {
      case 0:
        destination = const HomeScreen();
        break;
      case 1:
        destination = const MoodScreen();
        break;
      case 2:
        destination = const FeedScreen();
        break;
      case 3:
        destination = const ResourceScreen();
        break;
      case 4:
      default:
        destination = const SettingsScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      "assets/images/icons/home_nav.png",
      "assets/images/icons/mood_nav.png",
      "assets/images/icons/feed_nav.png",
      "assets/images/icons/resource_nav.png",
      "assets/images/icons/settings_nav.png",
    ];

    final selectedItems = [
      "assets/images/icons/home_select.png",
      "assets/images/icons/mood_select.png",
      "assets/images/icons/feed_select.png",
      "assets/images/icons/resource_select.png",
      "assets/images/icons/settings_select.png",
    ];

    final labels = ['Home', 'Echo', 'Circle', 'Archive', 'Settings'];

    double navWidth = MediaQuery.of(context).size.width - 16;

    return SafeArea(
      bottom: true,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 30, 92, 33).withOpacity(0.85),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ), 
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                BottomNavigationBar(
                  currentIndex: currentIndex,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  showSelectedLabels: true,
                  showUnselectedLabels: true,
                  selectedItemColor: Colors.white,
                  unselectedItemColor: const Color.fromARGB(179, 255, 255, 255),
                  onTap: (index) => _onItemTapped(context, index),
                  items: List.generate(
                    items.length,
                    (index) => BottomNavigationBarItem(
                      icon: AnimatedScale(
                        scale: currentIndex == index ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutBack,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6.0, bottom: 2.0),
                          child: Image.asset(
                            currentIndex == index
                                ? selectedItems[index]
                                : items[index],
                            height: 36,
                          ),
                        ),
                      ),
                      label: labels[index],
                    ),
                  ),
                ),

                // Gliding indicator
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: navWidth * (0.1 + 0.2 * currentIndex) - 16,
                  top: 0,
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.6),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
