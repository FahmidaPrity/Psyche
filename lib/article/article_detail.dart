import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math';

class BottomCurveClipper extends CustomClipper<Path> {
  static const double curveDepth = 50.0;

  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - curveDepth);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - curveDepth,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class ArticleDetail extends StatelessWidget {
  final String title;
  final String content;
  final String? imageUrl;

  const ArticleDetail({
    super.key,
    required this.title,
    required this.content,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    const double imageAreaHeight = 350.0;
    const double curveHeight = BottomCurveClipper.curveDepth;
    const double minSheetSize = 0.6;

    final Widget fallbackImage = Container(
      color: Colors.green.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.article, size: 80, color: Colors.white70),
    );

    final Widget articleImage = imageUrl != null && imageUrl!.isNotEmpty
        ? Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallbackImage,
          )
        : fallbackImage;

    final double screenHeight = MediaQuery.of(context).size.height;
    final double naturalSheetStartRatio =
        (screenHeight - (imageAreaHeight - curveHeight)) / screenHeight;
    final double initialSheetSize = max(minSheetSize, naturalSheetStartRatio);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/backgrounds/bg_details.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
            child: Container(color: Colors.white.withOpacity(0.2)),
          ),

          SizedBox(
            height: imageAreaHeight,
            width: double.infinity,
            child: ClipPath(
              clipper: BottomCurveClipper(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  articleImage,
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          DraggableScrollableSheet(
            initialChildSize: initialSheetSize,
            minChildSize: minSheetSize,
            maxChildSize: 0.95,
            builder: (context, controller) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: ListView(
                    controller: controller,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1D3B2E),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        content,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.7,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
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
