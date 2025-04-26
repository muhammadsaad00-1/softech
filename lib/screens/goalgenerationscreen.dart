import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class GoalGenerationScreen extends StatefulWidget {
  @override
  State<GoalGenerationScreen> createState() => _GoalGenerationScreenState();
}

class _GoalGenerationScreenState extends State<GoalGenerationScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  List<String> _subtasks = [];

  Future<void> _generateSubtasksAndSave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _controller.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _subtasks = [];
    });

    try {
      final prompt =
          "Break down the following goal into 5-7 actionable subtasks. Only list the subtasks as bullet points without any explanation or extra text:\nGoal: ${_controller.text}";
      final response = await Gemini.instance.text(prompt);

      // Parse Gemini's response into bullet points
      final output = response?.output?.trim() ?? '';
      final bullets = output
          .split(RegExp(r'[\n•\-]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      setState(() => _subtasks = bullets);

      // Parse main goal into title, due date, and category
      final parsedGoal = _parseNaturalLanguage(_controller.text);

      // Save goal with full structure
      final goalDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .add({
        'title': parsedGoal['title'],
        'dueDate': parsedGoal['dueDate'],
        'category': parsedGoal['category'],
        'createdAt': DateTime.now(),
        'isCompleted': false,
      });

      for (final subtask in bullets) {
        await goalDoc.collection('subtasks').add({
          'subtaskTitle': subtask,
          'isCompleted': false,
          'createdAt': DateTime.now(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Goal and subtasks created successfully!')),
      );

    } catch (e) {
      setState(() => _subtasks = []);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate subtasks: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ---------- These methods are reused from TaskCreationScreen ----------
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
      RegExp(r'next week'): () => DateTime.now().add(Duration(days: 7)),
      RegExp(r'\b(\d{1,2}/\d{1,2}/\d{4})\b'): (match) =>
          DateFormat('dd/MM/yyyy').parse(match.group(1)!),
    };

    for (final entry in patterns.entries) {
      final match = entry.key.firstMatch(input);
      if (match != null) {
        return entry.value is Function()
            ? (entry.value as Function()).call()
            : (entry.value as Function(Match)).call(match);
      }
    }
    return null;
  }

  String _detectCategory(String input) {
    final keywords = {
      'Academic': ['study', 'assignment', 'exam', 'class', 'scholarship','job','internship'],
      'Hobby': ['read', 'movie', 'music', 'paint', 'drawing'],
      'Personal': ['buy', 'grocery', 'clean', 'wash', 'plan'],
      'Health': ['exercise', 'yoga', 'doctor', 'medication', 'health'],
      'Sports': ['basketball', 'football', 'cricket', 'volleyball', 'tennis', 'squash'],
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
        .replaceAll(RegExp(r'\b(tomorrow|next week|\d{1,2}/\d{1,2}/\d{4})\b'), '')
        .trim();
  }
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Goal'),
        backgroundColor: Colors.orange[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Enter your broad goal (e.g., Apply for a scholarship)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            _isLoading
                ? CircularProgressIndicator(color: Colors.orange)
                : ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800]),
              icon: Icon(Icons.task, color: Colors.white),
              label: Text('Generate Subtasks',
                  style: TextStyle(color: Colors.white)),
              onPressed: _generateSubtasksAndSave,
            ),
            if (_subtasks.isNotEmpty) ...[
              SizedBox(height: 16),
              Text("Generated Subtasks:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ..._subtasks.map((point) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("• ", style: TextStyle(color: Colors.orange)),
                  Expanded(child: Text(point)),
                ],
              )),
            ],
          ],
        ),
      ),
    );
  }
}
