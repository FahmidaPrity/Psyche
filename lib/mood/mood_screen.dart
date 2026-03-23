import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/bottom_navbar.dart';
import '../services/mood_ai_service.dart';
import 'mood_one.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  final supabase = Supabase.instance.client;
  bool _hasTodayEntry = false;
  bool _isLoading = true;
  Map<String, dynamic>? _todayEntry;
  String _selectedView = 'Check-ins';

  @override
  void initState() {
    super.initState();
    _checkTodayEntry();
    _checkAndTriggerAnalysis();
  }

  Future<void> _checkTodayEntry() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final startOfDay = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String();
    final endOfDay = DateTime(
      today.year,
      today.month,
      today.day,
      23,
      59,
      59,
    ).toIso8601String();

    final response = await supabase
        .from('moods')
        .select()
        .eq('user_id', user.id)
        .eq('status', 'completed')
        .gte('updated_at', startOfDay)
        .lte('updated_at', endOfDay)
        .order('updated_at', ascending: false);

    if (response.isNotEmpty) {
      setState(() {
        _hasTodayEntry = true;
        _todayEntry = response.first;
        _isLoading = false;
      });
    } else {
      setState(() {
        _hasTodayEntry = false;
        _todayEntry = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _checkAndTriggerAnalysis() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      var unanalyzedMoods = await supabase
          .from('moods')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'completed')
          .eq('is_analyzed', false)
          .order('updated_at', ascending: true);

      if (unanalyzedMoods.isNotEmpty && mounted) {
        print('Found ${unanalyzedMoods.length} unanalyzed moods');

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        int processedCount = 0;
        while (unanalyzedMoods.isNotEmpty) {
          print('Processing mood ${processedCount + 1}...');
          await _performAnalysis();
          processedCount++;

          unanalyzedMoods = await supabase
              .from('moods')
              .select()
              .eq('user_id', user.id)
              .eq('status', 'completed')
              .eq('is_analyzed', false)
              .order('updated_at', ascending: true);
        }

        if (mounted) Navigator.of(context).pop();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Analyzed $processedCount mood(s)!"),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _selectedView = 'Reflections';
          });
        }
      }
    } catch (e) {
      print('Error in _checkAndTriggerAnalysis: $e');
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _performAnalysis() async {
    try {
      print('Starting analysis...');
      final result = await MoodAIService.analyzeDailyMood();
      print('Analysis result: $result');

      if (result['success'] == true) {
        final overallMood = result['overall_mood'] as String;
        final moodDistribution =
            result['mood_distribution'] as Map<String, int>;
        final dailyAnalysis = result['daily_analysis'] as Map<String, dynamic>;
        final selectedMoodSummary = result['selected_mood_summary'] as String?;
        final analyzedIds = result['analyzed_ids'] as List<String>;
        final combinedNotes = result['combined_notes'] as String;

        double totalConfidence = 0;
        int count = 0;
        dailyAnalysis.forEach((key, value) {
          if (value['confidence'] != null) {
            totalConfidence += value['confidence'];
            count++;
          }
        });
        final avgConfidence = count > 0 ? totalConfidence / count : 0.0;

        final user = supabase.auth.currentUser;
        if (user == null) return;

        print(
          'Inserting reflection: mood=$overallMood, confidence=$avgConfidence',
        );

        await supabase.from('reflections').insert({
          'user_id': user.id,
          'analysis_date': DateTime.now().toIso8601String(),
          'ai_predicted_mood': overallMood,
          'selected_mood_summary': selectedMoodSummary,
          'confidence': avgConfidence,
          'analyzed_mood_ids': analyzedIds,
          'combined_notes': combinedNotes,
          'mood_distribution': moodDistribution,
        });

        for (var moodId in analyzedIds) {
          await supabase
              .from('moods')
              .update({'is_analyzed': true})
              .eq('id', moodId);
        }

        print('Analysis completed successfully');
      } else {
        print('Analysis failed: ${result['error']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Analysis failed: ${result['error']}"),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    } catch (e) {
      print('Error in _performAnalysis: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _handleFabPressed() {
    if (_hasTodayEntry) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You've already added your mood today!")),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MoodOneScreen()),
    ).then((_) {
      _checkTodayEntry();
      _checkAndTriggerAnalysis();
    });
  }

  bool _canEdit(DateTime updatedAt) {
    final now = DateTime.now();
    return updatedAt.year == now.year &&
        updatedAt.month == now.month &&
        updatedAt.day == now.day;
  }

  void _onCounterTap(String viewType) {
    setState(() {
      _selectedView = viewType;
    });
  }

  void _showEditMessage(bool canEdit) {
    if (canEdit) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.construction,
                    size: 56,
                    color: Color.fromARGB(255, 56, 142, 60),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Coming Soon!",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 46, 125, 50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Edit feature will be added soon.\nStay tuned for updates!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 56, 142, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      "Got it!",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Editing not allowed after the day ends."),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildReflectionsView(String userId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase
          .from('reflections')
          .select()
          .eq('user_id', userId)
          .order('analysis_date', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.psychology, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  "No reflections yet",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Complete a check-in to get your first AI analysis",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final reflections = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: reflections.length,
          itemBuilder: (context, index) {
            final reflection = reflections[index];
            final analysisDate = reflection['analysis_date'] != null
                ? DateTime.parse(reflection['analysis_date'])
                : DateTime.now();
            final aiMood = reflection['ai_predicted_mood'] as String;
            final selectedMood = reflection['selected_mood_summary'] as String?;
            final confidence = reflection['confidence'] as num?;

            final recommendations = MoodAIService.getRecommendations(aiMood);
            final moodColor = Color(recommendations['color']);
            final isUrgent = recommendations['urgent'] ?? false;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.65),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${analysisDate.day} ${_monthName(analysisDate.month)} ${analysisDate.year}",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: moodColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: moodColor, width: 2),
                    ),
                    child: Row(
                      children: [
                        Text(
                          recommendations['emoji'],
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "AI Analysis:",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                aiMood.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: moodColor,
                                ),
                              ),
                              if (confidence != null)
                                Text(
                                  "${(confidence * 100).toStringAsFixed(1)}% confidence",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (selectedMood != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Your selected mood: $selectedMood",
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isUrgent ? Icons.warning : Icons.lightbulb,
                          color: isUrgent ? Colors.red : Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            recommendations['message'],
                            style: TextStyle(
                              fontSize: 13,
                              color: isUrgent
                                  ? Colors.red.shade900
                                  : Colors.black87,
                              fontWeight: isUrgent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "What you can do:",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  ...List<Widget>.generate(
                    (recommendations['tips'] as List).take(3).length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${i + 1}. ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: moodColor,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              recommendations['tips'][i],
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCheckInsView(List<Map<String, dynamic>> moods) {
    if (moods.isEmpty) {
      return const Center(
        child: Text(
          "No check-ins yet. Start tracking your mood!",
          style: TextStyle(fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: moods.length,
      itemBuilder: (context, index) {
        final data = moods[index];
        final updatedAt = data['updated_at'] != null
            ? DateTime.tryParse(data['updated_at'])
            : null;
        final formattedDate = updatedAt != null
            ? "${updatedAt.day} ${_monthName(updatedAt.month)}"
            : "Unknown";
        final title = (data['note_title'] ?? "No Title") as String;
        final description = (data['note_description'] ?? "") as String;
        final selectedMood = data['selected_mood'] as String?;

        final List<dynamic>? reasons = data['reasons'];
        final List<dynamic>? feelings = data['feelings'];

        return GestureDetector(
          onTap: () {
            if (updatedAt != null) {
              _showEditMessage(_canEdit(updatedAt));
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (selectedMood != null)
                      Chip(
                        label: Text(
                          selectedMood,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.blue.shade100,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    if (reasons != null)
                      ...reasons
                          .where((e) => (e as String).trim().isNotEmpty)
                          .map(
                            (e) => Chip(
                              label: Text(e),
                              backgroundColor: Colors.green.shade50,
                            ),
                          ),
                    if (feelings != null)
                      ...feelings
                          .where((e) => (e as String).trim().isNotEmpty)
                          .map(
                            (e) => Chip(
                              label: Text(e),
                              backgroundColor: Colors.indigo.shade50,
                            ),
                          ),
                  ],
                ),
                if (description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final userId = user?.id;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text("Please sign in to view your mood history.")),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/backgrounds/bg_mood.jpg",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  FutureBuilder<Map<String, int>>(
                    future: _getCounts(userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(height: 54);
                      }
                      final counts =
                          snapshot.data ?? {'checkins': 0, 'reflections': 0};
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTopCounter(
                            "Reflections",
                            counts['reflections']!,
                          ),
                          _buildTopCounter("Check-ins", counts['checkins']!),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  Expanded(
                    child: _selectedView == 'Reflections'
                        ? _buildReflectionsView(userId)
                        : FutureBuilder<List<Map<String, dynamic>>>(
                            future: supabase
                                .from('moods')
                                .select()
                                .eq('user_id', userId)
                                .eq('status', 'completed')
                                .order('updated_at', ascending: false),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (!snapshot.hasData) {
                                return const Center(
                                  child: Text("Error loading moods"),
                                );
                              }
                              return _buildCheckInsView(snapshot.data!);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _isLoading
          ? null
          : Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(
                      255,
                      46,
                      125,
                      50,
                    ).withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 3,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                backgroundColor: const Color.fromARGB(181, 89, 151, 92),
                elevation: 0,
                onPressed: _handleFabPressed,
                child: Image.asset(
                  _hasTodayEntry
                      ? 'assets/images/icons/tick.gif'
                      : 'assets/images/icons/add.png',
                  height: 35,
                ),
              ),
            ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Future<Map<String, int>> _getCounts(String userId) async {
    try {
      final checkinsData = await supabase
          .from('moods')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'completed');

      final reflectionsData = await supabase
          .from('reflections')
          .select('id')
          .eq('user_id', userId);

      return {
        'checkins': (checkinsData as List).length,
        'reflections': (reflectionsData as List).length,
      };
    } catch (e) {
      print('Error getting counts: $e');
      return {'checkins': 0, 'reflections': 0};
    }
  }

  Widget _buildTopCounter(String label, int count) {
    final bool isSelected = _selectedView == label;
    return GestureDetector(
      onTap: () => _onCounterTap(label),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? const Color.fromARGB(255, 200, 230, 201)
                  : Colors.white,
              border: isSelected
                  ? Border.all(
                      color: const Color.fromARGB(255, 56, 142, 60),
                      width: 2,
                    )
                  : null,
            ),
            child: Center(
              child: Text(
                "$count",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? const Color.fromARGB(255, 46, 125, 50)
                      : const Color.fromARGB(221, 0, 0, 0),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? const Color.fromARGB(255, 46, 125, 50)
                  : const Color.fromARGB(221, 0, 0, 0),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }
}
