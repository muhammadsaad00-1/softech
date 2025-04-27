// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import '../task_repository.dart';
//
//
// class TaskEditScreen extends StatefulWidget {
//   final Task task;
//
//   const TaskEditScreen({Key? key, required this.task}) : super(key: key);
//
//   @override
//   _TaskEditScreenState createState() => _TaskEditScreenState();
// }
//
// class _TaskEditScreenState extends State<TaskEditScreen> {
//   late TextEditingController _titleController;
//   late DateTime _selectedDate;
//   late String _selectedCategory;
//   late bool _isCompleted;
//   final List<String> _categories = [
//     'Academic', 'Hobby', 'Personal', 'Health', 'Sports', 'Miscellaneous'
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _titleController = TextEditingController(text: widget.task.title);
//     _selectedDate = widget.task.dueDate;
//     _selectedCategory = widget.task.category;
//     _isCompleted = widget.task.isCompleted;
//   }
//
//   @override
//   void dispose() {
//     _titleController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate,
//       firstDate: DateTime.now(),
//       lastDate: DateTime(2100),
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = DateTime(
//           picked.year,
//           picked.month,
//           picked.day,
//           _selectedDate.hour,
//           _selectedDate.minute,
//         );
//       });
//     }
//   }
//
//   Future<void> _selectTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.fromDateTime(_selectedDate),
//     );
//     if (picked != null) {
//       setState(() {
//         _selectedDate = DateTime(
//           _selectedDate.year,
//           _selectedDate.month,
//           _selectedDate.day,
//           picked.hour,
//           picked.minute,
//         );
//       });
//     }
//   }
//
//   void _saveTask() {
//     final taskRepository = Provider.of<TaskRepository>(context, listen: false);
//
//     // Update task with new values
//     final updatedTask = Task(
//       id: widget.task.id,
//       title: _titleController.text.trim(),
//       dueDate: _selectedDate,
//       category: _selectedCategory,
//       createdAt: widget.task.createdAt,
//       isCompleted: _isCompleted,
//       isSynced: false,
//     );
//
//     taskRepository.updateTask(updatedTask);
//     Navigator.pop(context);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Edit Task'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.check),
//             onPressed: _saveTask,
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             TextField(
//               controller: _titleController,
//               decoration: InputDecoration(
//                 labelText: 'Task Title',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             SizedBox(height: 20),
//             Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold)),
//             ListTile(
//               title: Text(DateFormat('EEEE, MMM d, yyyy').format(_selectedDate)),
//               trailing: Icon(Icons.calendar_today),
//               onTap: () => _selectDate(context),
//             ),
//             ListTile(
//               title: Text(DateFormat('h:mm a').format(_selectedDate)),
//               trailing: Icon(Icons.access_time),
//               onTap: () => _selectTime(context),
//             ),
//             SizedBox(height: 20),
//             Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
//             DropdownButtonFormField<String>(
//               value: _selectedCategory,
//               items: _categories.map((category) {
//                 return DropdownMenuItem(
//                   value: category,
//                   child: Text(category),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 setState(() {
//                   _selectedCategory = value!;
//                 });
//               },
//               decoration: InputDecoration(
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             SizedBox(height: 20),
//             CheckboxListTile(
//               title: Text('Completed'),
//               value: _isCompleted,
//               onChanged: (value) {
//                 setState(() {
//                   _isCompleted = value!;
//                 });
//               },
//             ),
//             SizedBox(height: 40),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _saveTask,
//                 child: Padding(
//                   padding: EdgeInsets.symmetric(vertical: 12),
//                   child: Text('Save Changes', style: TextStyle(fontSize: 16)),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }