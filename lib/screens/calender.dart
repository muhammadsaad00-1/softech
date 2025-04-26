import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late TaskDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    _dataSource = TaskDataSource([]);
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .get();
    final tasks = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'title': data['title'],
        'dueDate': (data['dueDate'] as Timestamp).toDate(),
        'category': data['category'],
      };
    }).toList();
    setState(() {
      _dataSource = TaskDataSource(tasks);
    });
  }

  void _onDragEnd(AppointmentDragEndDetails details) async {
    final appointment = details.appointment;
    if (appointment == null) return;

    // Cast to the correct type
    final appt = appointment as Appointment;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(appt.id as String?) // Now this works!
        .update({'dueDate': Timestamp.fromDate(details.droppingTime!)});
    _loadTasks(); // Refresh calendar
  }

  void _onTap(CalendarTapDetails details) {
    if (details.targetElement == CalendarElement.appointment && details.appointments != null) {
      final appointment = details.appointments!.first;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(appointment.subject),
          content: Text('Category: ${appointment.notes}\n'
              'Due: ${appointment.startTime}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
            TextButton(
              onPressed: () {
                // Implement edit logic here
                Navigator.pop(context);
              },
              child: Text('Edit'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Planner / Calendar'),
        backgroundColor: Colors.orange[800],
      ),
      body: SfCalendar(
        view: CalendarView.month, // Change to .week or .day as needed
        dataSource: _dataSource,
        allowDragAndDrop: true,
        onDragEnd: _onDragEnd,
        onTap: _onTap,
        showNavigationArrow: true,
        showDatePickerButton: true,
        monthViewSettings: MonthViewSettings(
          appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
        ),
      ),
    );
  }
}


class TaskDataSource extends CalendarDataSource {
  TaskDataSource(List<Map<String, dynamic>> tasks) {
    appointments = tasks.map((task) => Appointment(
      id: task['id'],
      startTime: task['dueDate'],
      endTime: (task['dueDate'] as DateTime).add(Duration(hours: 1)),
      subject: task['title'],
      color: _getCategoryColor(task['category']),
      notes: task['category'],
      isAllDay: false,
    )).toList();
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Academic': return Colors.blue;
      case 'Personal': return Colors.orange;
      case 'Health': return Colors.green;
      case 'Sports': return Colors.red;
      case 'Hobby': return Colors.purple;
      default: return Colors.grey;
    }
  }
}

