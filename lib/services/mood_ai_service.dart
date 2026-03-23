import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class MoodAIService {
  static final _supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>> analyzeDailyMood() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'User not logged in'};
      }

      final moodsRes = await _supabase
          .from('moods')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'completed')
          .eq('is_analyzed', false)
          .order('created_at', ascending: true)
          .limit(1);

      if (moodsRes.isEmpty) {
        return {'success': false, 'error': 'No mood data found'};
      }

      final List<String> analyzedIds = [];
      final List<String> notesList = [];
      final Map<String, dynamic> results = {};
      final Map<String, int> moodCounts = {};
      final Map<String, int> selectedMoodCounts = {};

      for (var mood in moodsRes) {
        final id = mood['id'] as String;
        analyzedIds.add(id);

        final title = mood['note_title'] ?? '';
        final desc = mood['note_description'] ?? '';
        final text = "$title. $desc".trim();
        notesList.add(text);

        final selectedMood = mood['selected_mood'] as String?;
        if (selectedMood != null) {
          selectedMoodCounts[selectedMood] =
              (selectedMoodCounts[selectedMood] ?? 0) + 1;
        }

        String aiMood = 'Calm';
        double confidence = 0.5;

        if (text.isNotEmpty && text.length > 3) {
          print('Analyzing text: $text');
          final prediction = await _predictMood(text);
          print('Prediction result: $prediction');

          if (prediction['success'] == true) {
            final rawMood = prediction['mood'] as String;
            print('Raw mood from model: $rawMood');
            aiMood = _normalizeMood(rawMood);
            confidence = (prediction['confidence'] as num).toDouble();
            print('Normalized mood: $aiMood (confidence: $confidence)');
          } else {
            print('Prediction failed: ${prediction['error']}');
          }
        } else {
          print('Text too short or empty, using default mood');
        }

        moodCounts[aiMood] = (moodCounts[aiMood] ?? 0) + 1;

        results[id] = {
          'date': mood['created_at'],
          'mood': aiMood,
          'confidence': confidence,
          'recommendation': getRecommendations(aiMood),
        };
      }

      final String combinedNotes = notesList.join('\n\n');

      String? maxMood;
      int maxCount = 0;
      moodCounts.forEach((mood, count) {
        if (count > maxCount) {
          maxMood = mood;
          maxCount = count;
        }
      });

      final overallMood = maxMood ?? 'Calm';

      String? selectedMoodSummary;
      if (selectedMoodCounts.isNotEmpty) {
        selectedMoodSummary = selectedMoodCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      return {
        'success': true,
        'daily_analysis': results,
        'overall_mood': overallMood,
        'mood_distribution': moodCounts,
        'selected_mood_summary': selectedMoodSummary,
        'analyzed_ids': analyzedIds,
        'combined_notes': combinedNotes,
        'overall_recommendation': getRecommendations(overallMood),
      };
    } catch (e) {
      print('Error in analyzeDailyMood: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> _predictMood(String text) async {
    try {
      final startUrl = Uri.parse(
        "https://fahmida-prity-psyche.hf.space/gradio_api/call/predict",
      );

      print('Calling API: $startUrl');

      final startRes = await http
          .post(
            startUrl,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "data": [text],
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('Start response status: ${startRes.statusCode}');
      print('Start response body: ${startRes.body}');

      if (startRes.statusCode != 200) {
        return {'success': false, 'error': 'HTTP ${startRes.statusCode}'};
      }

      final startJson = jsonDecode(startRes.body);
      final eventId = startJson["event_id"];
      if (eventId == null) {
        return {'success': false, 'error': 'No event_id returned'};
      }

      print('Event ID: $eventId');

      const maxAttempts = 30;
      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        await Future.delayed(const Duration(seconds: 2));

        final resultUrl = Uri.parse(
          "https://fahmida-prity-psyche.hf.space/gradio_api/call/predict/$eventId",
        );

        try {
          final resultRes = await http
              .get(resultUrl)
              .timeout(const Duration(seconds: 5));

          if (resultRes.statusCode != 200) {
            continue;
          }

          print('Attempt $attempt response: ${resultRes.body}');

          final lines = resultRes.body.split('\n');
          for (var line in lines) {
            line = line.trim();
            if (line.startsWith('data:')) {
              final jsonStr = line.substring(5).trim();
              try {
                final dataArray = jsonDecode(jsonStr);
                print('Parsed data: $dataArray');

                if (dataArray is List && dataArray.isNotEmpty) {
                  final mood = dataArray[0].toString();
                  final confidence = (dataArray.length > 1)
                      ? (dataArray[1] is num ? dataArray[1] : 0.7)
                      : 0.7;

                  print('Extracted mood: $mood, confidence: $confidence');

                  return {
                    'success': true,
                    'mood': mood,
                    'confidence': confidence,
                  };
                }
              } catch (e) {
                print('JSON parse error: $e');
                continue;
              }
            }
          }
        } catch (e) {
          print('Request error on attempt $attempt: $e');
          continue;
        }
      }

      return {'success': false, 'error': 'Timeout waiting for model output'};
    } catch (e) {
      print(' Error in _predictMood: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static String _normalizeMood(String mood) {
    final lower = mood.toLowerCase().trim();

    print('Normalizing mood: "$lower"');

    if (lower == 'calm' ||
        lower == 'happy' ||
        lower == 'peaceful' ||
        lower == 'content') {
      return 'Calm';
    }
    if (lower == 'sad' ||
        lower == 'low' ||
        lower == 'depressed' ||
        lower == 'down') {
      return 'Low';
    }
    if (lower == 'suicidal' || lower == 'hopeless') {
      return 'Suicidal';
    }
    if (lower == 'tired' ||
        lower == 'drained' ||
        lower == 'exhausted' ||
        lower == 'fatigued') {
      return 'Drained';
    }
    if (lower == 'anxious' ||
        lower == 'worried' ||
        lower == 'nervous' ||
        lower == 'stressed') {
      return 'Anxious';
    }
    if (lower == 'angry' ||
        lower == 'frustrated' ||
        lower == 'irritated' ||
        lower == 'annoyed') {
      return 'Frustrated';
    }

    if (lower.contains('calm') ||
        lower.contains('happy') ||
        lower.contains('good') ||
        lower.contains('great') ||
        lower.contains('peaceful') ||
        lower.contains('content')) {
      return 'Calm';
    }
    if (lower.contains('sad') ||
        lower.contains('low') ||
        lower.contains('depress')) {
      return 'Low';
    }
    if (lower.contains('suicid')) {
      return 'Suicidal';
    }
    if (lower.contains('tired') ||
        lower.contains('drain') ||
        lower.contains('exhaust') ||
        lower.contains('fatig')) {
      return 'Drained';
    }
    if (lower.contains('anxious') ||
        lower.contains('anxiety') ||
        lower.contains('worr') ||
        lower.contains('nervous') ||
        lower.contains('stress')) {
      return 'Anxious';
    }
    if (lower.contains('angry') ||
        lower.contains('frustrat') ||
        lower.contains('irritat') ||
        lower.contains('annoy')) {
      return 'Frustrated';
    }

    print('No match found, defaulting to Calm');
    return 'Calm';
  }

  static Map<String, dynamic> getRecommendations(String mood) {
    final recommendations = {
      'Calm': {
        'emoji': '😌',
        'message':
            'Great job! You\'ve been maintaining a calm and peaceful state.',
        'tips': [
          'Continue your current routines and habits',
          'Practice gratitude journaling daily',
          'Share your peace-building strategies with others',
          'Maintain your sleep and exercise schedule',
        ],
        'color': 0xFF4CAF50,
      },
      'Low': {
        'emoji': '😔',
        'message': 'You\'ve been feeling low. Remember, this is temporary.',
        'tips': [
          'Reach out to a trusted friend or family member',
          'Engage in activities you usually enjoy',
          'Maintain regular sleep and meal schedules',
          'Consider speaking with a counselor if this persists',
          'Take a short walk in nature daily',
        ],
        'color': 0xFF9E9E9E,
      },
      'Suicidal': {
        'emoji': '⚠️',
        'message':
            'URGENT: Your safety is the priority. Please seek help immediately.',
        'tips': [
          '🆘 Call Bangladesh crisis helpline: 10659',
          '📞 Contact Kaan Pete Roi: 09612-019019',
          '🏥 Visit your nearest emergency room NOW',
          '👥 Reach out to a trusted person immediately',
          '💬 Text a friend or family member about how you feel',
        ],
        'urgent': true,
        'color': 0xFFD32F2F,
      },
      'Drained': {
        'emoji': '😮‍💨',
        'message':
            'You\'ve been feeling drained. Rest and self-care are essential.',
        'tips': [
          'Prioritize 8-9 hours of quality sleep',
          'Take regular breaks throughout the day',
          'Reduce non-essential commitments temporarily',
          'Practice gentle exercises like walking or stretching',
          'Say "no" to additional responsibilities',
        ],
        'color': 0xFFFF9800,
      },
      'Anxious': {
        'emoji': '😰',
        'message':
            'Anxiety has been prevalent. Let\'s work on managing it together.',
        'tips': [
          'Practice 4-7-8 breathing: inhale 4s, hold 7s, exhale 8s',
          'Try grounding: 5 things you see, 4 hear, 3 touch, 2 smell, 1 taste',
          'Limit caffeine and sugar intake',
          'Write down your worries to externalize them',
          'Consider professional anxiety management techniques',
        ],
        'color': 0xFFFFC107,
      },
      'Frustrated': {
        'emoji': '😤',
        'message':
            'Frustration shows you care. Let\'s channel it constructively.',
        'tips': [
          'Identify specific frustration sources — what can you control?',
          'Engage in physical exercise to release tension',
          'Practice progressive muscle relaxation',
          'Talk it out with someone you trust',
          'Take 10-minute breaks when feeling overwhelmed',
        ],
        'color': 0xFFFF5722,
      },
      'Unknown': {
        'emoji': '🤔',
        'message':
            'We couldn\'t determine a clear mood pattern from the entries.',
        'tips': [
          'Try adding more detailed notes in future check-ins',
          'Continue tracking your moods regularly',
          'Consider reviewing your recent activities',
        ],
        'color': 0xFF9E9E9E,
      },
    };

    return recommendations[mood] ?? recommendations['Calm']!;
  }
}
