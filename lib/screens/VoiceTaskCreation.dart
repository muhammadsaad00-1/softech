import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../homeview.dart';
import 'notifications.dart';

class VoiceTaskWidget extends StatefulWidget {
  const VoiceTaskWidget({super.key});

  @override
  _VoiceTaskWidgetState createState() => _VoiceTaskWidgetState();
}

class _VoiceTaskWidgetState extends State<VoiceTaskWidget> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _textController = TextEditingController();
  bool _isListening = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  void _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Status: $status'),
      onError: (error) => print('Error: $error'),
    );
    if (!available && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
    }
  }

  void _startListening() async {
    if (!_isListening) {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _textController.text = result.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
      );
    }
  }

  void _stopListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    }
  }

  Future<void> _createTaskFromSpeech() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final parsedTask = _parseSpeechInput(_textController.text);

    await _firestore.collection('users').doc(user.uid).collection('tasks').add({
      'title': parsedTask['title'],
      'dueDate': parsedTask['dueDate'],
      'category': parsedTask['category'],
      'createdAt': DateTime.now(),
      'isCompleted': false,
    });

    setState(() {
      _textController.clear();
    });
    await scheduleNotificationsForTasks();
    Navigator.push(context, MaterialPageRoute(builder: (context)=> HomeView(emotion: 'normal')));
  }

  Map<String, dynamic> _parseSpeechInput(String input) {
    final now = DateTime.now();
    final detectedCategory = _detectCategory(input);
    return {
      'title': input,
      'dueDate': now.add(const Duration(days: 1)),
      'category': detectedCategory,
    };
  }

  String _detectCategory(String input) {
    final keywords = {
      'Academic': ['study', 'assignment', 'exam', 'class', 'job', 'scholarship'],
      'Hobby': ['read', 'movie', 'music'],
      'Personal': ['buy', 'grocery', 'clean', 'wash'],
      'Health': ['exercise', 'yoga', 'doctor', 'medication'],
      'Sports': ['basketball', 'football', 'cricket', 'volleyball', 'tennis', 'squash'],
    };

    for (final entry in keywords.entries) {
      if (entry.value.any((word) => input.toLowerCase().contains(word))) {
        return entry.key;
      }
    }
    return 'Miscellaneous';
  }

  @override
  void dispose() {
    _speech.stop();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Task Title',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton(
              onPressed: _isListening ? _stopListening : _startListening,
              backgroundColor: Colors.orange[800],
              heroTag: 'micButton',
              child: Icon(
                _isListening ? Icons.mic_off : Icons.mic,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            FloatingActionButton(
              onPressed: _createTaskFromSpeech,
              backgroundColor: Colors.green[700],
              heroTag: 'saveButton',
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
