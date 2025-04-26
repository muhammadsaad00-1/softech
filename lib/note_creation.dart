import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter_gemini/flutter_gemini.dart";  // Correct
import 'package:firebase_auth/firebase_auth.dart';

class NoteCreationScreen extends StatefulWidget {
  @override
  State<NoteCreationScreen> createState() => _NoteCreationScreenState();
}

class _NoteCreationScreenState extends State<NoteCreationScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  List<String> _summary = [];

  Future<void> _summarizeAndSave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _controller.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _summary = [];
    });

    try {
      final prompt =
          "Summarize the following note in 3-5 concise bullet points. Only provide the bullet points, no introduction or explanation:\n${_controller.text}";
      final response = await Gemini.instance.text(prompt);

      // Parse Gemini's response into bullet points
      final output = response?.output?.trim() ?? '';
      final bullets = output
          .split(RegExp(r'[\n•\-]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .take(5)
          .toList();

      setState(() => _summary = bullets);

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .add({
        'rawText': _controller.text,
        'summary': bullets,
        'createdAt': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note summarized and saved!')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _summary = []);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to summarize: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Note'),
        backgroundColor: Colors.orange[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              minLines: 6,
              maxLines: 15,
              decoration: InputDecoration(
                labelText: 'Enter your note',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            _isLoading
                ? CircularProgressIndicator(color: Colors.orange)
                : ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800]),
              icon: Icon(Icons.summarize, color: Colors.white),
              label: Text('Summarize & Save',
                  style: TextStyle(color: Colors.white)),
              onPressed: _summarizeAndSave,
            ),
            if (_summary.isNotEmpty) ...[
              SizedBox(height: 16),
              Text("Summary:", style: TextStyle(fontWeight: FontWeight.bold)),
              ..._summary.map((point) => Row(
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
