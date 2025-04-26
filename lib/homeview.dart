import 'dart:math';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soft/screens/calender.dart';
import 'package:soft/screens/cameraORC.dart';
import 'package:soft/screens/dailyreport.dart';
import 'package:soft/screens/goalgenerationscreen.dart';
import 'package:soft/screens/mooddetection.dart';
import 'package:soft/screens/notifications.dart';
import 'package:soft/screens/taskcreation.dart';
import 'package:soft/settings_screen.dart';

import 'app_settings.dart';
import 'notes_home.dart';

class HomeView extends StatefulWidget {
  final String emotion;
  const HomeView({super.key, required this.emotion});


  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> affirmations = [
    "You have the power to create change.",
    "You're stronger than you think.",
    "Today is full of possibilities.",
    "Your potential is endless.",
    "Every small step matters.",
    "You've got this, keep going!",
    "Trust yourself, you know the way.",
    "Your hard work will pay off.",
    "You are making progress every day.",
    "You are capable of amazing things."
  ];

  @override
  void initState() {
    super.initState();
    _checkAndShowAffirmation();
    initLocalNotifications();
  }


  Future<void> _checkAndShowAffirmation() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getInt('lastAffirmationTime') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // Check if an hour (3,600,000 milliseconds) has passed since the last affirmation
    if (currentTime - lastShown >= 360000) {
      // Update the last shown timestamp
      await prefs.setInt('lastAffirmationTime', currentTime);

      // Show the affirmation after the widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAffirmationDialog();
      });
    }
  }

  void _showAffirmationDialog() {
    // Get a random affirmation
    final random = Random();
    final affirmation = affirmations[random.nextInt(affirmations.length)];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'You Can Do This!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          affirmation,
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Thanks!', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filterTasksByEmotion(List<Map<String, dynamic>> tasks) {
    final emotion = widget.emotion.toLowerCase();

    return tasks.where((task) {
      final category = (task['category'] as String).toLowerCase();

      switch (emotion) {
        case 'normal':
          return true;
        case 'happy':
          return category == 'Hobby';
        case 'sad':
          return category == 'Health';
        case 'tired':
          return category == 'Personal' || category == 'Hobby';
        case 'lazy':
          return category == 'Miscellaneous';
        case 'productive':
          return category == 'Academic';
        case 'angry':
          return category == 'Sports';
        default:
          return true;
      }
    }).toList();
  }


  Future<List<Map<String, dynamic>>> _fetchTasks() async {
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('tasks')
        .where('isCompleted', isEqualTo: false)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        ...data,
        'dueDate': (data['dueDate'] as Timestamp).toDate(),
      };
    }).toList();
  }



  Future<void> _toggleTaskCompletion(String taskId, bool currentStatus) async {
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('tasks')
        .doc(taskId)
        .update({'isCompleted': !currentStatus});

    setState(() {}); // Refresh UI
  }

  void _showTaskDetails(BuildContext context, Map<String, dynamic> task) async {
    final List<Map<String, dynamic>> subtasks = await _fetchSubtasks(task['id']);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(task['title'], style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 10),
              _DetailRow(Icons.category, 'Category: ${task['category']}'),
              _DetailRow(Icons.calendar_today,
                  'Due: ${DateFormat('MMM dd, yyyy – hh:mm a').format(task['dueDate'])}'),
              if (task['description'] != null && task['description'].toString().isNotEmpty)
                _DetailRow(Icons.description, task['description']),

              if (subtasks.isNotEmpty) ...[
                SizedBox(height: 20),
                Text('Subtasks:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                ...subtasks.map((subtask) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: GestureDetector(
                    onTap: () => _toggleSubtaskCompletion(task['id'], subtask['id'], subtask['isCompleted'] ?? false),
                    child: Row(
                      children: [
                        Icon(
                          subtask['isCompleted'] == true
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 18,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            subtask['subtaskTitle'] ?? 'No Title',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }
  Future<List<Map<String, dynamic>>> _fetchSubtasks(String taskId) async {
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('tasks')
        .doc(taskId)
        .collection('subtasks')
        .where('isCompleted', isEqualTo: false)  // Only incomplete subtasks
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,        // Add ID to identify subtask later
        ...data,
      };
    }).toList();
  }
  Future<void> _toggleSubtaskCompletion(String taskId, String subtaskId, bool currentStatus) async {
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('tasks')
        .doc(taskId)
        .collection('subtasks')
        .doc(subtaskId)
        .update({'isCompleted': !currentStatus});

    setState(() {}); // Refresh UI
  }

  Widget _taskItem(Map<String, dynamic> task) => Card(
    elevation: 2,
    margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
    child: ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getCategoryColor(task['category']),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.task, color: Colors.white),
      ),
      title: Text(
        task['title'],
        style: TextStyle(
          fontSize: 16,
          decoration: task['isCompleted']
              ? TextDecoration.lineThrough
              : TextDecoration.none,
        ),
      ),
      subtitle: Text(
        DateFormat('MMM dd, yyyy').format(task['dueDate']),
        style: TextStyle(color: Colors.grey[600]),
      ),
      trailing: Checkbox(
        value: task['isCompleted'],
        onChanged: (value) => _toggleTaskCompletion(task['id'], task['isCompleted']),
        activeColor: Colors.orange,
      ),
      onTap: () => _showTaskDetails(context, task),
    ),
  );

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Academic':
        return Colors.blue;
      case 'Personal':
        return Colors.orange;
      case 'Health':
        return Colors.green;
      default:
        return Colors.purple;
    }
  }
  Drawer customDrawer() => Drawer(
    child: ListView(
      children: <Widget>[
        DrawerHeader(child: Text('Navigation Sidebar')),
        ListTile(
          leading: Icon(Icons.task),
          title: Text('Tasks'),
          onTap: () {
            Navigator.pop(context); // close drawer
            // Already on HomeView, so do nothing or pop to root
          },
        ),
        ListTile(
          leading: Icon(Icons.notes),
          title: Text('Notes'),
          onTap: () {
            Navigator.pop(context); // close drawer
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotesHome()),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.emoji_emotions_rounded),
          title: Text('Mood'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MoodDetector()),
            );// close drawer
            // Already on HomeView, so do nothing or pop to root
          },
        ),
        ListTile(
          leading: Icon(Icons.wine_bar),
          title: Text('Goals'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => GoalGenerationScreen()),
            );// close drawer
            // Already on HomeView, so do nothing or pop to root
          },
        ),
        ListTile(
          leading: Icon(Icons.camera),
          title: Text('Camera'),
          onTap: () async {
            final cameras = await availableCameras();
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CameraOCRScreen(cameras: (cameras))),
            );
            ListTile(
              leading: Icon(Icons.mood),
              title: Text('Mood Journal'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MoodDetector()),
                );
              },
            )
            ;// close drawer
            // Already on HomeView, so do nothing or pop to root
          },
        ),
        ListTile(
          leading: Icon(Icons.calendar_month),
          title: Text('Calender'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CalendarScreen()),
            );// close drawer
            // Already on HomeView, so do nothing or pop to root
          },
        ),
        ListTile(
          leading: Icon(Icons.newspaper),
          title: Text('Report'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RecentTasksScreen()),
            );// close drawer
            // Already on HomeView, so do nothing or pop to root
          },
        ),
        // Add more ListTiles for other features here
      ],
    ),
  );


  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final isDark = settings.themeMode == ThemeMode.dark;

    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop(); // smooth exit
        return false; // prevent default back action
      },
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TaskCreationScreen()),
          ),
          backgroundColor: Colors.orange,
          child: Icon(Icons.add),
        ),
        appBar: AppBar(
          title: Text("Tasks", style: Theme.of(context).appBarTheme.titleTextStyle),
          elevation: 1,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
            ),
          ],
        ),
        drawer: customDrawer(),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchTasks(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(child: CircularProgressIndicator(color: Colors.orange));
            }

            final tasks = snapshot.data ?? [];
            final filteredTasks = _filterTasksByEmotion(tasks);

            return filteredTasks.isEmpty
                ? Center(child: Text('No matching tasks!', style: TextStyle(fontSize: 18)))
                : ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) => _taskItem(filteredTasks[index]),
            );
          },
        ),
      ),
    );
  }}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}