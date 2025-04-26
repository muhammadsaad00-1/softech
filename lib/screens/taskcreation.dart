import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:soft/homeview.dart';
import 'package:soft/screens/VoiceTaskCreation.dart';
import '../app_settings.dart';
import 'notifications.dart';

class TaskCreationScreen extends StatefulWidget {
  @override
  _TaskCreationScreenState createState() => _TaskCreationScreenState();
}

class _TaskCreationScreenState extends State<TaskCreationScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> _createTask(String input) async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // First validate and correct the input text
      final correctedText = await _validateAndCorrectText(input);
      if (correctedText != input) {
        _showSnackbar('Task text was corrected: "$correctedText"', Colors.orange);
        _controller.text = correctedText; // Update the textfield with corrected version
      }

      final parsedTask = _parseNaturalLanguage(correctedText);

      await _firestore.collection('users').doc(user.uid).collection('tasks').add({
        'title': parsedTask['title'],
        'dueDate': parsedTask['dueDate'],
        'category': parsedTask['category'],
        'createdAt': DateTime.now(),
        'isCompleted': false,
      });

      _controller.clear();
      _showSnackbar('Task created successfully!', Colors.green);
      await scheduleNotificationsForTasks();
    } catch (e) {
      _showSnackbar('Error: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _validateAndCorrectText(String input) async {
    try {
      final prompt = '''
      Analyze this text for spelling and grammar errors. If the text contains real words 
      and is correct, return ONLY the exact same text. If there are misspellings or incorrect 
      words, provide ONLY the corrected version without any explanations or additional text.
      
      Text to analyze: "$input"
      ''';

      final response = await Gemini.instance.text(prompt);
      return response?.output?.trim() ?? input;
    } catch (e) {
      print('Gemini error: $e');
      return input; // Fallback to original text if error occurs
    }
  }

  Map<String, dynamic> _parseNaturalLanguage(String input) {
    final now = DateTime.now();
    final dueDate = _extractDate(input) ?? now.add(Duration(days: 1));
    final category = _detectCategory(input);
    final cleanTitle = _cleanTaskTitle(input);

    return {
      'title': cleanTitle,
      'dueDate': dueDate,
      'category': category,
    };
  }

  DateTime? _extractDate(String input) {
    final patterns = {
      RegExp(r'tomorrow'): () => DateTime.now().add(Duration(days: 1)),
      RegExp(r'half an hour'): () => DateTime.now().add(Duration(minutes: 30)),
      RegExp(r'an hour'): () => DateTime.now().add(Duration(minutes: 60)),
      RegExp(r'35 minutes'): () => DateTime.now().add(Duration(minutes: 35)),

      RegExp(r'half hour'): () => DateTime.now().add(Duration(minutes: 30)),
      RegExp(r'two days'): () => DateTime.now().add(Duration(days: 2)),
      RegExp(r'next week'): () => DateTime.now().add(Duration(days: 7)),
      RegExp(r'\b(\d{1,2}/\d{1,2}/\d{4})\b'): (match) =>
          DateFormat('dd/MM/yyyy').parse(match.group(1)!),
    };

    for (final entry in patterns.entries) {
      final match = entry.key.firstMatch(input);
      if (match != null) {
        return entry.value is Function() ?
        (entry.value as Function()).call() :
        (entry.value as Function(Match)).call(match);
      }
    }
    return null;
  }

  String _detectCategory(String input) {
    final keywords = {
      'Academic': ['study', 'assignment', 'exam', 'class','job','scholarship'],
      'Hobby': ['read','movie','music'],
      'Personal': ['buy', 'grocery', 'clean', 'wash'],
      'Health': ['exercise', 'yoga', 'doctor', 'medication'],
      'Sports': ['basketball','football','cricket','volleyball','tennis','squash']
    };

    for (final entry in keywords.entries) {
      if (entry.value.any((word) => input.toLowerCase().contains(word))) {
        return entry.key;
      }
    }
    return 'Miscellaneous';
  }

  String _cleanTaskTitle(String input) {
    return input
        .replaceAll(RegExp(r'\b(day|week|half hour|half an hour| in| hour|tomorrow|next week|\d{1,2}/\d{1,2}/\d{4})\b'), '')
        .trim();
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final isDark = settings.themeMode == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('New Task', style: Theme.of(context).appBarTheme.titleTextStyle),

        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'What needs to be done?',
                hintText: 'e.g., "Buy milk tomorrow" or "Finish report by 25/12/2024"',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 3,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator(color: Colors.orange)
                : ElevatedButton.icon(
              icon: Icon(Icons.add_task, color: Colors.white),
              label: Text('Create Task',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[800],
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final input = _controller.text.trim();
                if (input.isNotEmpty) await _createTask(input);
                Navigator.push(context, MaterialPageRoute(builder: (context)=> HomeView(emotion: 'normal')));
              },
            ),
            VoiceTaskWidget()
          ],
        ),
      ),
    );
  }
}