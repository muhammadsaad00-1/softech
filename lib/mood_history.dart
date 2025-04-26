import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:soft/mood_model.dart';

class MoodHistory extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(child: Text("Please log in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Mood History"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(user.uid)
            .collection('moods')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final moods = snapshot.data!.docs
              .map((doc) => MoodEntry.fromFirestore(doc))
              .toList();

          if (moods.isEmpty) {
            return Center(child: Text("No mood entries yet"));
          }

          return ListView.builder(
            itemCount: moods.length,
            itemBuilder: (context, index) {
              final mood = moods[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getMoodColor(mood.mood),
                    child: Text(_getMoodEmoji(mood.mood)),
                  ),
                  title: Text(mood.mood),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('MMM dd, yyyy - hh:mm a').format(mood.date)),
                      if (mood.note != null) Text(mood.note!),
                      if (mood.intensity != null)
                        Row(
                          children: [
                            Text("Intensity: "),
                            for (int i = 0; i < mood.intensity!; i++)
                              Icon(Icons.star, size: 16, color: Colors.amber),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy': return Colors.yellow;
      case 'sad': return Colors.blue;
      case 'angry': return Colors.red;
      case 'excited': return Colors.orange;
      case 'tired': return Colors.grey;
      case 'loving': return Colors.pink;
      case 'productive': return Colors.green;
      case 'lazy': return Colors.brown;
      default: return Colors.purple;
    }
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy': return '😊';
      case 'sad': return '😢';
      case 'angry': return '😠';
      case 'excited': return '🤩';
      case 'tired': return '😴';
      case 'loving': return '🥰';
      case 'productive': return '💪';
      case 'lazy': return '🦥';
      default: return '😐';
    }
  }
}