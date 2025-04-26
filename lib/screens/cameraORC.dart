// camera_ocr_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CameraOCRScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraOCRScreen({super.key, required this.cameras});

  @override
  State<CameraOCRScreen> createState() => _CameraOCRScreenState();
}

class _CameraOCRScreenState extends State<CameraOCRScreen> {
  late CameraController _controller;
  final textRecognizer = TextRecognizer();
  String _extractedText = '';
  bool _isProcessing = false;
  final _gemini = Gemini.instance;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _isValidJson(String jsonString) {
    try {
      jsonDecode(jsonString);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    _controller = CameraController(
      widget.cameras.first,
      ResolutionPreset.medium,
    );
    await _controller.initialize();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _processImage() async {
    setState(() => _isProcessing = true);

    try {
      final image = await _controller.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await textRecognizer.processImage(inputImage);

      _extractedText = recognizedText.text;
      await _createTaskFromOCRText();
    } finally {
      setState(() => _isProcessing = false);
    }
  }



  Future<void> _createTaskFromOCRText() async {
    try {
      final prompt = '''
    Extract task details from: "$_extractedText".
    Return STRICT JSON without markdown:
    {
      "title": "concise task title",
      
    }
    ''';
      final response = await _gemini.text(prompt);
      final rawJson = response?.output ?? '';

      // Sanitize Gemini response
      final jsonString = rawJson
          .replaceAll(RegExp(r'``````|\n'), '') // Remove all markdown
          .trim();

      print('Sanitized JSON: $jsonString');

      final taskData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Handle dueDate (set to now if null)
      final dueDate = taskData['dueDate'] != null
          ? DateTime.parse(taskData['dueDate'])
          : DateTime.now();

      // Handle category with fallback to 'miscellaneous'
      final category = _validateCategory(
          taskData['category']?.toString() ?? '',
          {
            'Academic': ['study', 'assignment', 'exam', 'class','job','scholarship'],
            'Hobby': ['read','movie','music'],
            'Personal': ['buy', 'grocery', 'clean', 'wash'],
            'Health': ['exercise', 'yoga', 'doctor', 'medication'],
            'Sports': ['basketball','football','cricket','volleyball','tennis','squash']
          }
      );

      // Save to Firestore
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).collection('tasks').add({
          'title': (taskData['title'] ?? 'Untitled Task').toString().trim(),
          'dueDate': Timestamp.fromDate(dueDate),
          'category': category,
          'createdAt': Timestamp.now(),
          'isCompleted': false,
        });
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error creating task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create task: ${e.toString()}')),
      );
    }
  }

  String _validateCategory(String input, Map<String, List<String>> categories) {
    final cleanInput = input.trim().toLowerCase();

    // Find matching category
    final matchedCategory = categories.keys.firstWhere(
            (key) => categories[key]!.any((word) => cleanInput.contains(word)),
        orElse: () => 'miscellaneous'
    );

    return matchedCategory;
  }


  @override
  void dispose() {
    _controller.dispose();
    textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text('Scan Task'), backgroundColor: Colors.orange),
      body: Column(
        children: [
          Expanded(
            child: CameraPreview(_controller),
          ),
          _isProcessing
              ? Center(child: CircularProgressIndicator(color: Colors.orange))
              : ElevatedButton.icon(
            icon: Icon(Icons.camera_alt, color: Colors.white),
            label: Text('Capture & Process', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: _processImage,
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
