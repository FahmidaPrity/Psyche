import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewer extends StatefulWidget {
  final String pdfUrl;
  final String bookId;

  const PdfViewer({super.key, required this.pdfUrl, required this.bookId});

  @override
  State<PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  int _lastPage = 1;
  bool _isDocLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadLastPage();
  }

  Future<void> _loadLastPage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('${widget.bookId}_lastPage') ?? 1;
    setState(() {
      _lastPage = saved;
    });
  }

  Future<void> _saveProgress(int currentPage, int totalPages) async {
    if (totalPages <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final progress = (currentPage / totalPages).clamp(0.0, 1.0);
    await prefs.setDouble('${widget.bookId}_progress', progress);
    await prefs.setInt('${widget.bookId}_lastPage', currentPage);
  }

  Future<double> _readProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('${widget.bookId}_progress') ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Reader'),
        actions: [
          IconButton(
            tooltip: 'Go to last read page',
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              final page = _lastPage > 0 ? _lastPage : 1;
              _pdfViewerController.jumpToPage(page);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SfPdfViewer.network(
            widget.pdfUrl,
            controller: _pdfViewerController,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              final int total = _pdfViewerController.pageCount;
              final int toPage = (_lastPage <= total && _lastPage >= 1)
                  ? _lastPage
                  : 1;
              if (toPage > 1) {
                _pdfViewerController.jumpToPage(toPage);
              }
              setState(() {
                _isDocLoaded = true;
              });
            },
            onPageChanged: (PdfPageChangedDetails details) {
              final int current = details.newPageNumber;
              final int total = _pdfViewerController.pageCount;
              if (total > 0) {
                _saveProgress(current, total);
              }
            },
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to load PDF: ${details.error}')),
              );
            },
          ),
          if (!_isDocLoaded) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }
}
