import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'pdf_viewer.dart';
import '../widgets/bottom_navbar.dart';

class BookDetail extends StatefulWidget {
  final String title;
  final String author;
  final String imagePath;
  final double? progress;
  final String description;
  final int pages;
  final String publishedDate;
  final String? pdfUrl;

  const BookDetail({
    super.key,
    required this.title,
    required this.author,
    required this.imagePath,
    this.progress,
    required this.description,
    required this.pages,
    required this.publishedDate,
    this.pdfUrl,
  });

  @override
  State<BookDetail> createState() => _BookDetailState();
}

class _BookDetailState extends State<BookDetail> {
  double _progress = 0.0;
  bool _isDescriptionExpanded = false;
  static const Color _progressBarColor = Color(0xFF366845);

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getDouble('${widget.title}_progress');
    setState(() {
      if (stored != null) {
        _progress = stored.clamp(0.0, 1.0);
      } else if (widget.progress != null) {
        _progress = widget.progress!.clamp(0.0, 1.0);
      } else {
        _progress = 0.0;
      }
    });
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionBox() {
    const double maxDescriptionHeight = 150.0;
    const Color boxColor = Color.fromARGB(255, 237, 248, 238);

    return GestureDetector(
      onTap: () {
        setState(() {
          _isDescriptionExpanded = !_isDescriptionExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: boxColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: _isDescriptionExpanded
                        ? double.infinity
                        : maxDescriptionHeight,
                  ),
                  child: Text(
                    widget.description,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.fade,
                  ),
                ),
                if (!_isDescriptionExpanded)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            boxColor.withOpacity(0.0),
                            boxColor.withOpacity(0.9),
                            boxColor.withOpacity(1.0),
                          ],
                          stops: const [0.0, 0.8, 1.0],
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 5.0),
                          child: Text(
                            'See More...',
                            style: TextStyle(
                              color: Colors.green.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (_isDescriptionExpanded)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    'See Less',
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double scrollableBottomPadding = 100.0;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/backgrounds/bg_library.jpg",
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(color: Colors.white.withOpacity(0.25)),
              ),
            ),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              100,
              20,
              scrollableBottomPadding,
            ),
            child: Column(
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: widget.imagePath.startsWith('http')
                        ? Image.network(
                            widget.imagePath,
                            height: 200,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            widget.imagePath,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  "by ${widget.author}",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: widget.imagePath.startsWith('http')
                            ? Image.network(
                                widget.imagePath,
                                height: 60,
                                width: 45,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                widget.imagePath,
                                height: 60,
                                width: 45,
                                fit: BoxFit.cover,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "by ${widget.author}",
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: _progress,
                              backgroundColor: Colors.grey.shade300,
                              color: _progressBarColor,
                              minHeight: 6,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "${(_progress * 100).toInt()}% completed",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                _buildDescriptionBox(),

                const SizedBox(height: 20),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(
                      icon: Icons.menu_book,
                      title: "${widget.pages} Pages",
                      subtitle: "Page Count",
                      color: const Color(0xFF366845),
                    ),
                    const SizedBox(width: 15),
                    _buildInfoCard(
                      icon: Icons.calendar_today,
                      title: widget.publishedDate,
                      subtitle: "Published Date",
                      color: Colors.orange.shade700,
                    ),
                  ],
                ),

                if (widget.pdfUrl != null && widget.pdfUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 25.0),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PdfViewer(
                              pdfUrl: widget.pdfUrl!,
                              bookId: widget.title,
                            ),
                          ),
                        );
                        await _loadProgress();
                      },
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text(
                        'Dive to Read',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          190,
                          231,
                          194,
                        ),
                        foregroundColor: const Color(0xFF366845),
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        minimumSize: const Size(200, 40),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
}
