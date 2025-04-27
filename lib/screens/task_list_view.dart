// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import '../task_repository.dart';
// import 'task_edit_screen.dart';
//
// class TaskListView extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final taskRepository = Provider.of<TaskRepository>(context, listen: false);
//
//     return StreamBuilder<List<Task>>(
//       stream: taskRepository.tasksStream,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator());
//         }
//
//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }
//
//         final tasks = snapshot.data ?? [];
//         if (tasks.isEmpty) {
//           return Center(child: Text('No tasks yet. Add your first task!'));
//         }
//
//         return ListView.builder(
//           itemCount: tasks.length,
//           itemBuilder: (context, index) {
//             final task = tasks[index];
//             return TaskListTile(
//               task: task,
//               onToggleCompleted: (isCompleted) {
//                 task.isCompleted = isCompleted;
//                 taskRepository.updateTask(task);
//               },
//               onDelete: () {
//                 taskRepository.deleteTask(task.id!);
//               },
//               onEdit: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => TaskEditScreen(task: task),
//                   ),
//                 );
//               },
//             );
//           },
//         );
//       },
//     );
//   }
// }
//
// class TaskListTile extends StatelessWidget {
//   final Task task;
//   final Function(bool) onToggleCompleted;
//   final VoidCallback onDelete;
//   final VoidCallback onEdit;
//
//   const TaskListTile({
//     Key? key,
//     required this.task,
//     required this.onToggleCompleted,
//     required this.onDelete,
//     required this.onEdit,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
//
//     return Dismissible(
//       key: Key(task.id!),
//       background: Container(
//         color: Colors.red,
//         alignment: Alignment.centerRight,
//         padding: EdgeInsets.only(right: 20),
//         child: Icon(Icons.delete, color: Colors.white),
//       ),
//       direction: DismissDirection.endToStart,
//       onDismissed: (_) => onDelete(),
//       child: Card(
//         margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//         child: ListTile(
//           contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           leading: Checkbox(
//             value: task.isCompleted,
//             onChanged: (value) => onToggleCompleted(value ?? false),
//           ),
//           title: Text(
//             task.title,
//             style: TextStyle(
//               decoration: task.isCompleted ? TextDecoration.lineThrough : null,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           subtitle: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               SizedBox(height: 4),
//               Text('Due: ${dateFormat.format(task.dueDate)}'),
//               Text('Category: ${task.category}'),
//               if (!task.isSynced)
//                 Row(
//                   children: [
//                     Icon(Icons.cloud_off, size: 16, color: Colors.grey),
//                     SizedBox(width: 4),
//                     Text('Not synced', style: TextStyle(color: Colors.grey, fontSize: 12)),
//                   ],
//                 ),
//             ],
//           ),
//           trailing: IconButton(
//             icon: Icon(Icons.edit, color: Colors.blue),
//             onPressed: onEdit,
//           ),
//         ),
//       ),
//     );
//   }
// }