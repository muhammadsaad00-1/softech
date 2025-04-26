import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:soft/homeview.dart';
import '../app_settings.dart';
import '../mood_history.dart';
import '../mood_insights.dart';  // Make sure to import these

class MoodDetector extends StatefulWidget {
  const MoodDetector({super.key});

  @override
  State<MoodDetector> createState() => _MoodDetectorState();
}

class _MoodDetectorState extends State<MoodDetector> {
  final List<String> emojis = [
    'loving',
    'excited',
    'tired',
    'happy',
    'productive',
    'angry',
    'lazy',
    'sad'
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _selectedMood;
  TextEditingController _noteController = TextEditingController();
  int _intensity = 3;

  Future<void> _logMood() async {
    if (_selectedMood == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).collection('moods').add({
        'mood': _selectedMood,
        'note': _noteController.text.isNotEmpty ? _noteController.text : null,
        'date': DateTime.now(),
        'intensity': _intensity,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mood logged successfully!')),
      );

      _noteController.clear();
      setState(() {
        _selectedMood = null;
        _intensity = 3;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging mood: $e')),
      );
    }
  }

  void _goToHomeWithMood() {
    if (_selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a mood first')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomeView(emotion: _selectedMood!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final isDark = settings.themeMode == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(
        title:  Text(
          "Current Mood",
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Tell us how you currently feel?",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 20),

            // Mood Selection Grid
            SizedBox(
              height: 160,
              child: ListView.builder(
                itemCount: emojis.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  String emojiTitle = emojis[index];
                  return Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedMood = emojiTitle;
                          });
                        },
                        child: Container(
                          width: 100,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _selectedMood == emojiTitle
                                  ? Colors.orange
                                  : Colors.transparent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Image.asset(
                                  'assets/images/emoji${index + 1}.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                emojiTitle,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_selectedMood != null) ...[
              SizedBox(height: 30),

              // Mood Intensity Slider
              Text(
                "How strong is this feeling?",
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Slider(
                value: _intensity.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: _intensity.toString(),
                onChanged: (value) {
                  setState(() {
                    _intensity = value.toInt();
                  });
                },
              ),

              SizedBox(height: 20),

              // Optional Note
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Add a note (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'What\'s making you feel $_selectedMood?',
                ),
                maxLines: 3,
              ),

              SizedBox(height: 20),

              // Log Mood Button
              ElevatedButton.icon(
                icon: Icon(Icons.save),
                label: Text("Log My Mood"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: _logMood,
              ),

              SizedBox(height: 10),

              // Go to HomeView Button
              OutlinedButton.icon(
                icon: Icon(Icons.home),
                label: Text("View Tasks for $_selectedMood"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: BorderSide(color: Colors.orange),
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: _goToHomeWithMood,
              ),
            ],

            // New: Mood Insights and History Buttons at the bottom
            SizedBox(height: 30),
            Divider(),
            SizedBox(height: 10),
            Text(
              "View Your Mood Data",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.insights, color: Colors.orange),
                    label: Text("Mood Insights"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: BorderSide(color: Colors.orange),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MoodInsights()),
                      );
                    },
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.history, color: Colors.orange),
                    label: Text("Mood History"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: BorderSide(color: Colors.orange),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MoodHistory()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}