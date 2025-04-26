import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void initLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Ask permission manually using permission_handler
  if (await Permission.notification.request().isGranted) {
    print('Notification permission granted');
  } else {
    print('Notification permission denied');
  }
}



Future<void> scheduleNotificationsForTasks() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final tasksSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('tasks')
      .where('isCompleted', isEqualTo: false)
      .get();

  for (final doc in tasksSnapshot.docs) {
    final data = doc.data();
    final dueDate = (data['dueDate'] as Timestamp).toDate();
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.inMinutes <= 30 && difference.inMinutes > 0) {
      sendNotification(data['title']);
    }
  }
}

Future<void> sendNotification(String taskTitle) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
    'your_channel_id',
    'Task Reminders',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );

  const NotificationDetails platformChannelSpecifics =
  NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    'Upcoming Task!',
    'Your task "$taskTitle" is due soon!',
    platformChannelSpecifics,
  );
}
