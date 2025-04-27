import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationCenterScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Center'),
        backgroundColor: Colors.orange[800],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getCombinedTaskStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading notifications'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final tasks = _processTasks(snapshot.data!.docs);

          return _buildNotificationList(tasks['upcoming']!, tasks['missed']!);
        },
      ),
    );
  }

  Stream<QuerySnapshot> _getCombinedTaskStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    final now = DateTime.now();
    final next12Hours = now.add(Duration(hours: 12));

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .where('isCompleted', isEqualTo: false)
        .snapshots();
  }

  Map<String, List<QueryDocumentSnapshot>> _processTasks(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    final upcomingTasks = <QueryDocumentSnapshot>[];
    final missedTasks = <QueryDocumentSnapshot>[];

    for (final doc in docs) {
      final dueDate = (doc['dueDate'] as Timestamp).toDate();

      if (dueDate.isBefore(now)) {
        missedTasks.add(doc);
      } else if (dueDate.isBefore(now.add(Duration(hours: 12)))) {
        upcomingTasks.add(doc);
        _scheduleNotification(doc);
      }
    }

    return {'upcoming': upcomingTasks, 'missed': missedTasks};
  }

  void _scheduleNotification(QueryDocumentSnapshot task) async {
    final dueDate = (task['dueDate'] as Timestamp).toDate();
    final notificationTime = dueDate.subtract(Duration(hours: 12));

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: task.id.hashCode,
        channelKey: 'scheduled_tasks',
        title: 'Task Reminder: ${task['title']}',
        body: 'Due in 12 hours - ${DateFormat('MMM dd, hh:mm a').format(dueDate)}',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(date: notificationTime),
    );
  }

  Widget _buildNotificationList(List<QueryDocumentSnapshot> upcoming, List<QueryDocumentSnapshot> missed) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        if (upcoming.isNotEmpty) ...[
          _buildSectionHeader('Upcoming Reminders (12hr)'),
          ...upcoming.map((doc) => _buildReminderCard(doc)),
        ],
        if (missed.isNotEmpty) ...[
          _buildSectionHeader('Missed Tasks'),
          ...missed.map((doc) => _buildMissedTaskCard(doc)),
        ],
        if (upcoming.isEmpty && missed.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('No notifications!', style: TextStyle(fontSize: 18)),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.orange[800],
      ),
    ),
  );

  Widget _buildReminderCard(QueryDocumentSnapshot task) => Card(
    margin: EdgeInsets.symmetric(vertical: 4),
    child: ListTile(
      leading: Icon(Icons.notifications_active, color: Colors.orange),
      title: Text(task['title']),
      subtitle: Text('Due: ${_formatDate(task['dueDate'])}'),
      trailing: IconButton(
        icon: Icon(Icons.check),
        onPressed: () => _markTaskComplete(task.id),
      ),
    ),
  );

  Widget _buildMissedTaskCard(QueryDocumentSnapshot task) => Card(
    color: Colors.red[50],
    margin: EdgeInsets.symmetric(vertical: 4),
    child: ListTile(
      leading: Icon(Icons.warning_amber_rounded, color: Colors.red),
      title: Text(task['title'], style: TextStyle(color: Colors.red)),
      subtitle: Text('Overdue since ${_formatDate(task['dueDate'])}'),
      trailing: IconButton(
        icon: Icon(Icons.check, color: Colors.red),
        onPressed: () => _markTaskComplete(task.id),
      ),
    ),
  );

  Future<void> _markTaskComplete(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(taskId)
        .update({'isCompleted': true});
  }

  String _formatDate(Timestamp timestamp) {
    return DateFormat('MMM dd, yyyy – hh:mm a').format(timestamp.toDate());
  }
}
