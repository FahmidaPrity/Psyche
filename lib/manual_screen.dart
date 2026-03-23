import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ManualScreen extends StatelessWidget {
  const ManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Background
          Container(
            height: size.height,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/backgrounds/bg_manual.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Blur Overlay
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.4),
                      Colors.green.shade50.withOpacity(0.3),
                      Colors.white.withOpacity(0.2),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Stack(
              children: [
                // Scrollable Manual Content
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      Text(
                        "User Manual",
                        style: GoogleFonts.poppins(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                          letterSpacing: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Because even the best of us sometimes forget which button does what.",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.green.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      _buildSection(
                        title: "1. The Home Screen",
                        text:
                            "Ah, the gateway to your self-reflection empire. Here you’ll find inspiring quotes that rotate every few seconds, consider them your mental espresso shots. Below, those colorful boxes lead to different parts of your journey: emotions, community, articles, and resources.",
                      ),
                      _buildSection(
                        title: "2. Echoes of Your Heart (Mood Tracker)",
                        text:
                            "Feeling sunny? Cloudy? Existentially overcast? This is where you log it all. The more honest you are, the better your reflection becomes. Think of it as a mirror, but for your soul, and one that doesn’t judge your bedhead.",
                      ),
                      _buildSection(
                        title: "3. Gather in the Circle (Feed)",
                        text:
                            "A safe, supportive space where others share thoughts, feelings, and tiny victories. Comment, engage, or just read, lurking is still personal growth if you’re learning something.",
                      ),
                      _buildSection(
                        title: "4. Articles",
                        text:
                            "Carefully curated reads on mental health, wellness, and being human in the modern age. No fluff, no pop psychology nonsense, just insights worth your time.",
                      ),
                      _buildSection(
                        title: "5. Library",
                        text:
                            "A sanctuary of resources, research, guides, and self-help material. Browse at your pace. Knowledge doesn’t spoil.",
                      ),
                      _buildSection(
                        title: "6. Settings & Personalization",
                        text:
                            "This is your control room. You can adjust preferences, access this manual again, or even take a quiet exit when needed. Your data stays yours, no surprise newsletters here.",
                      ),
                      _buildSection(
                        title: "7. The Fine Print (A.K.A. Reality Check)",
                        text:
                            "This app supports you, but it’s not a therapist. If you’re going through something serious, please reach out to a trusted professional. We’re your friendly co-pilot, not the autopilot.",
                      ),
                      const SizedBox(height: 40),
                      Divider(
                        color: Colors.green.shade300.withOpacity(0.7),
                        thickness: 1.2,
                        indent: 40,
                        endIndent: 40,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Manual written with care, and a bit of caffeine.",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.green.shade700.withOpacity(0.8),
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),

                // Back Button (top-left)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.green,
                      ),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Back',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.4),
              Colors.green.shade100.withOpacity(0.25),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade200.withOpacity(0.4),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.5,
                color: Colors.green.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
