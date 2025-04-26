import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:soft/screens/taskcreation.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  void _showTaskDetails(BuildContext context, Map<String, dynamic> task) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(task['title'], style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 10),
            _DetailRow(Icons.category, 'Category: ${task['category']}'),
            _DetailRow(Icons.calendar_today,
                'Due: ${DateFormat('MMM dd, yyyy – hh:mm a').format(task['dueDate'])}'),
            if (task['description'] != null)
              _DetailRow(Icons.description, task['description']),
          ],
        ),
      ),
    );
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
      case 'academic':
        return Colors.blue;
      case 'personal':
        return Colors.orange;
      case 'health':
        return Colors.green;
      default:
        return Colors.purple;
    }
  }
  Drawer _customDrawer() => Drawer(
      child: ListView(
          children: <Widget>[
            DrawerHeader(child: Text('Navigation Sidebar')),
            ListTile(
              title: Text('ini listnya'),
            ),
            ListTile(
              title: Text('ini listnya'),
            ),
            ListTile(
              title: Text('ini listnya'),
            ),
            ListTile(
              title: Text('ini listnya'),
            )
          ]
      )
  );


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TaskCreationScreen()),
        ),
        backgroundColor: Colors.orange,
        child: Icon(Icons.add),
      ),
      appBar: AppBar(
        title: Text("Tasks"),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      drawer: _customDrawer(),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          final tasks = snapshot.data ?? [];

          return tasks.isEmpty
              ? Center(child: Text('No pending tasks!', style: TextStyle(fontSize: 18)))
              : ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) => _taskItem(tasks[index]),
          );
        },
      ),
    );
  }
}

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
