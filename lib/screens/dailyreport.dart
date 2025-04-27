import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soft/Login/initialpage.dart';
import 'package:soft/auth/auth_view_model.dart';
import 'package:soft/mood_model.dart';

import '../auth/utils.dart';

class RecentTasksScreen extends StatefulWidget {
  const RecentTasksScreen({Key? key}) : super(key: key);

  @override
  State<RecentTasksScreen> createState() => _RecentTasksScreenState();
}

class _RecentTasksScreenState extends State<RecentTasksScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;


  Future<void> _toggleTaskCompletion(String taskId, bool currentStatus) async {
    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .collection('tasks')
          .doc(taskId)
          .update({'isCompleted': !currentStatus});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating task: $e')),
      );
    }
  }

  Widget _buildMoodSnapshot(AsyncSnapshot<QuerySnapshot> moodSnapshot) {
    if (moodSnapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }

    if (moodSnapshot.hasError || moodSnapshot.data == null) {
      return const Text('Could not load mood data');
    }

    final moods = moodSnapshot.data!.docs
        .map((doc) => MoodEntry.fromFirestore(doc))
        .toList();

    if (moods.isEmpty) {
      return const Text('No mood data available');
    }

    // Count mood occurrences
    final moodCounts = <String, int>{};
    for (final mood in moods) {
      moodCounts[mood.mood] = (moodCounts[mood.mood] ?? 0) + 1;
    }

    // Sort by most frequent
    final sortedMoods = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Mood Today',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sortedMoods.take(3).map((entry) {
            return Chip(
              backgroundColor: _getMoodColor(entry.key),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getMoodEmoji(entry.key)),
                  const SizedBox(width: 4),
                  Text('${entry.key}: ${entry.value}'),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy': return Colors.yellow[200]!;
      case 'sad': return Colors.blue[200]!;
      case 'angry': return Colors.red[200]!;
      case 'excited': return Colors.orange[200]!;
      case 'tired': return Colors.grey[300]!;
      case 'loving': return Colors.pink[200]!;
      case 'productive': return Colors.green[200]!;
      case 'lazy': return Colors.brown[200]!;
      default: return Colors.purple[200]!;
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('User not authenticated'),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              try {
                await _auth.signOut();
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);
                user = null;
                Navigator.push(context, MaterialPageRoute(builder: (context)=> InitialPage()));
              } catch (e) {
                Utils.snackBar('Logout failed: ${e.toString()}', context);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Mood Snapshot Section
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .doc(currentUserId)
                .collection('moods')
                .where('date', isGreaterThanOrEqualTo: startOfDay)
                .where('date', isLessThan: endOfDay)
                .snapshots(),
            builder: (context, moodSnapshot) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildMoodSnapshot(moodSnapshot),
                  ),
                ),
              );
            },
          ),
          // Tasks Section
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(currentUserId)
                  .collection('tasks')
                  .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
                  .where('createdAt', isLessThan: endOfDay)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No tasks created today',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                final totalTasks = docs.length;
                final completedTasks = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['isCompleted'] == true;
                }).length;

                final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Today\'s Progress',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[300],
                            color: Colors.green,
                            minHeight: 8,
                          ),
                          const SizedBox(height: 8),
                          Text('${(progress * 100).toStringAsFixed(1)}% completed'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final task = docs[index];
                          final data = task.data() as Map<String, dynamic>;
                          final isCompleted = data['isCompleted'] ?? false;
                          final title = data['title'] ?? 'Untitled Task';
                          final description = data['description'];
                          final dueDate = data['dueDate'] != null
                              ? (data['dueDate'] as Timestamp).toDate()
                              : null;
                          final createdAt = (data['createdAt'] as Timestamp).toDate();

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            color: isCompleted ? Colors.green[50] : Colors.red[50],
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            decoration: isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                      ),
                                      Checkbox(
                                        value: isCompleted,
                                        onChanged: (value) =>
                                            _toggleTaskCompletion(task.id, isCompleted),
                                        activeColor: Colors.green,
                                      ),
                                    ],
                                  ),
                                  if (description != null && description.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      description,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Created: ${DateFormat('MMM dd, hh:mm a').format(createdAt)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  if (dueDate != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Due: ${DateFormat('MMM dd, hh:mm a').format(dueDate)}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        ],
      ),
    );
  }
}