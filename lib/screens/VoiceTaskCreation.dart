import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VoiceTaskCreation extends StatefulWidget {
  @override
  _VoiceTaskCreationState createState() => _VoiceTaskCreationState();
}

class _VoiceTaskCreationState extends State<VoiceTaskCreation> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _recognizedText = '';
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
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech recognition not available')),
      );
    }
  }

  void _startListening() async {
    if (!_isListening) {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });
        },
        listenFor: Duration(seconds: 30),
        pauseFor: Duration(seconds: 5),
        partialResults: true,
      );
    }
  }

  void _stopListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      if (_recognizedText.isNotEmpty) {
        _createTaskFromSpeech();
      }
    }
  }

  Future<void> _createTaskFromSpeech() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final parsedTask = _parseSpeechInput(_recognizedText);

    await _firestore.collection('users').doc(user.uid).collection('tasks').add({
      'title': parsedTask['title'],
      'dueDate': parsedTask['dueDate'],
      'category': parsedTask['category'],
      'createdAt': DateTime.now(),
      'isCompleted': false,
    });

    setState(() => _recognizedText = '');
  }

  Map<String, dynamic> _parseSpeechInput(String input) {
    // Reuse your existing NLU parsing logic here
    final now = DateTime.now();
    return {
      'title': input,
      'dueDate': now.add(Duration(days: 1)),
      'category': 'general',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Task Creation'),
        backgroundColor: Colors.orange[800],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(20),
              child: Text(
                _recognizedText,
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          VoiceControlButton(
            isListening: _isListening,
            startListening: _startListening,
            stopListening: _stopListening,
          ),
        ],
      ),
    );
  }
}

class VoiceControlButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback startListening;
  final VoidCallback stopListening;

  const VoiceControlButton({
    required this.isListening,
    required this.startListening,
    required this.stopListening,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 30),
      child: FloatingActionButton(
        onPressed: isListening ? stopListening : startListening,
        backgroundColor: Colors.orange[800],
        child: Icon(
          isListening ? Icons.mic_off : Icons.mic,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}
