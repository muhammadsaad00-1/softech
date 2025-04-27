// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import 'connectivity_service.dart';
//
// class Task {
//   String? id;
//   String title;
//   DateTime dueDate;
//   String category;
//   DateTime createdAt;
//   bool isCompleted;
//   bool isSynced;
//
//   Task({
//     this.id,
//     required this.title,
//     required this.dueDate,
//     required this.category,
//     required this.createdAt,
//     this.isCompleted = false,
//     this.isSynced = false,
//   });
//
//   factory Task.fromFirestore(DocumentSnapshot doc) {
//     final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//     return Task(
//       id: doc.id,
//       title: data['title'] ?? '',
//       dueDate: (data['dueDate'] as Timestamp).toDate(),
//       category: data['category'] ?? 'Miscellaneous',
//       createdAt: (data['createdAt'] as Timestamp).toDate(),
//       isCompleted: data['isCompleted'] ?? false,
//       isSynced: true,
//     );
//   }
//
//   Map<String, dynamic> toFirestore() {
//     return {
//       'title': title,
//       'dueDate': dueDate,
//       'category': category,
//       'createdAt': createdAt,
//       'isCompleted': isCompleted,
//     };
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'title': title,
//       'dueDate': dueDate.millisecondsSinceEpoch,
//       'category': category,
//       'createdAt': createdAt.millisecondsSinceEpoch,
//       'isCompleted': isCompleted,
//       'isSynced': isSynced,
//     };
//   }
//
//   factory Task.fromJson(Map<String, dynamic> json) {
//     return Task(
//       id: json['id'],
//       title: json['title'],
//       dueDate: DateTime.fromMillisecondsSinceEpoch(json['dueDate']),
//       category: json['category'],
//       createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
//       isCompleted: json['isCompleted'] ?? false,
//       isSynced: json['isSynced'] ?? false,
//     );
//   }
// }
//
// class TaskRepository {
//   static final TaskRepository _instance = TaskRepository._internal();
//   factory TaskRepository() => _instance;
//   TaskRepository._internal();
//
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final ConnectivityService _connectivityService = ConnectivityService();
//   late SharedPreferences _prefs;
//   bool _isInitialized = false;
//
//   // In-memory cache of tasks
//   List<Task> _localTasks = [];
//   final StreamController<List<Task>> _tasksStreamController = StreamController<List<Task>>.broadcast();
//   Stream<List<Task>> get tasksStream => _tasksStreamController.stream;
//
//   // Keys for offline storage
//   static const String _localTasksKey = 'local_tasks';
//   static const String _pendingOperationsKey = 'pending_operations';
//
//   // Pending operations to sync
//   List<Map<String, dynamic>> _pendingOperations = [];
//
//   Future<void> initialize() async {
//     if (_isInitialized) return;
//
//     _prefs = await SharedPreferences.getInstance();
//     await _connectivityService.initialize();
//
//     // Load local tasks from storage
//     await _loadLocalTasks();
//     await _loadPendingOperations();
//
//     // Listen for connectivity changes to trigger sync
//     _connectivityService.connectionStatusStream.listen((isConnected) {
//       if (isConnected) {
//         syncWithFirestore();
//       }
//     });
//
//     // Initialize sync if connected
//     if (_connectivityService.isConnected) {
//       syncWithFirestore();
//     }
//
//     _isInitialized = true;
//   }
//
//   Future<void> _loadLocalTasks() async {
//     try {
//       final tasksJson = _prefs.getStringList(_localTasksKey) ?? [];
//       _localTasks = tasksJson
//           .map((json) => Task.fromJson(jsonDecode(json)))
//           .toList();
//       _tasksStreamController.add(_localTasks);
//     } catch (e) {
//       print("Error loading local tasks: $e");
//       // If there's an error parsing the cached data, clear it
//       _localTasks = [];
//       await _prefs.setStringList(_localTasksKey, []);
//       _tasksStreamController.add(_localTasks);
//     }
//   }
//
//   Future<void> _saveLocalTasks() async {
//     try {
//       final tasksJson = _localTasks
//           .map((task) => jsonEncode(task.toJson()))
//           .toList();
//       await _prefs.setStringList(_localTasksKey, tasksJson);
//       _tasksStreamController.add(List<Task>.from(_localTasks));
//     } catch (e) {
//       print("Error saving local tasks: $e");
//     }
//   }
//
//   Future<void> _loadPendingOperations() async {
//     try {
//       final pendingOpsJson = _prefs.getStringList(_pendingOperationsKey) ?? [];
//       _pendingOperations = pendingOpsJson
//           .map((json) => jsonDecode(json) as Map<String, dynamic>)
//           .toList();
//     } catch (e) {
//       print("Error loading pending operations: $e");
//       _pendingOperations = [];
//       await _prefs.setStringList(_pendingOperationsKey, []);
//     }
//   }
//
//   Future<void> _savePendingOperations() async {
//     try {
//       final pendingOpsJson = _pendingOperations
//           .map((op) => jsonEncode(op))
//           .toList();
//       await _prefs.setStringList(_pendingOperationsKey, pendingOpsJson);
//     } catch (e) {
//       print("Error saving pending operations: $e");
//     }
//   }
//
//   // Add a new task
//   Future<void> addTask(Task task) async {
//     // Make sure we're initialized
//     if (!_isInitialized) {
//       await initialize();
//     }
//
//     // Create a new task with temporary ID
//     final newTask = Task(
//       id: 'temp_${DateTime.now().millisecondsSinceEpoch}', // Temporary ID
//       title: task.title,
//       dueDate: task.dueDate,
//       category: task.category,
//       createdAt: task.createdAt,
//       isCompleted: task.isCompleted,
//       isSynced: false,
//     );
//
//     // Add to local storage first
//     _localTasks.add(newTask);
//     await _saveLocalTasks();
//
//     // If online, sync immediately
//     if (_connectivityService.isConnected) {
//       try {
//         await _addTaskToFirestore(newTask);
//       } catch (e) {
//         print("Error syncing task to Firestore: $e");
//         // Add to pending operations if sync fails
//         _pendingOperations.add({
//           'type': 'add',
//           'taskId': newTask.id,
//         });
//         await _savePendingOperations();
//       }
//     } else {
//       // Otherwise, add to pending operations
//       _pendingOperations.add({
//         'type': 'add',
//         'taskId': newTask.id,
//       });
//       await _savePendingOperations();
//     }
//   }
//
//   // Update an existing task
//   Future<void> updateTask(Task task) async {
//     // Make sure we're initialized
//     if (!_isInitialized) {
//       await initialize();
//     }
//
//     // Update in local storage first
//     final index = _localTasks.indexWhere((t) => t.id == task.id);
//     if (index != -1) {
//       _localTasks[index] = task..isSynced = false;
//       await _saveLocalTasks();
//     } else {
//       print("Task not found locally: ${task.id}");
//       return;
//     }
//
//     // If online, sync immediately
//     if (_connectivityService.isConnected) {
//       try {
//         await _updateTaskInFirestore(task);
//       } catch (e) {
//         print("Error updating task in Firestore: $e");
//         // Add to pending operations if sync fails
//         _pendingOperations.add({
//           'type': 'update',
//           'taskId': task.id,
//         });
//         await _savePendingOperations();
//       }
//     } else {
//       // Otherwise, add to pending operations
//       _pendingOperations.add({
//         'type': 'update',
//         'taskId': task.id,
//       });
//       await _savePendingOperations();
//     }
//   }
//
//   // Delete a task
//   Future<void> deleteTask(String taskId) async {
//     // Make sure we're initialized
//     if (!_isInitialized) {
//       await initialize();
//     }
//
//     // Delete from local storage first
//     _localTasks.removeWhere((task) => task.id == taskId);
//     await _saveLocalTasks();
//
//     // If online, sync immediately
//     if (_connectivityService.isConnected) {
//       try {
//         await _deleteTaskFromFirestore(taskId);
//       } catch (e) {
//         print("Error deleting task from Firestore: $e");
//       }
//     } else {
//       // Otherwise, add to pending operations
//       _pendingOperations.add({
//         'type': 'delete',
//         'taskId': taskId,
//       });
//       await _savePendingOperations();
//     }
//   }
//
//   // Get all tasks (from local storage)
//   List<Task> getAllTasks() {
//     return List<Task>.from(_localTasks);
//   }
//
//   // Sync all local data with Firestore
//   Future<void> syncWithFirestore() async {
//     if (!_connectivityService.isConnected || _auth.currentUser == null) return;
//     if (!_isInitialized) {
//       await initialize();
//     }
//
//     try {
//       // Process pending operations
//       final operations = List<Map<String, dynamic>>.from(_pendingOperations);
//       for (final operation in operations) {
//         final taskId = operation['taskId'];
//         final operationType = operation['type'];
//
//         if (operationType == 'add') {
//           final taskIndex = _localTasks.indexWhere((t) => t.id == taskId);
//           if (taskIndex != -1) {
//             await _addTaskToFirestore(_localTasks[taskIndex]);
//             _pendingOperations.remove(operation);
//           }
//         } else if (operationType == 'update') {
//           final taskIndex = _localTasks.indexWhere((t) => t.id == taskId);
//           if (taskIndex != -1) {
//             await _updateTaskInFirestore(_localTasks[taskIndex]);
//             _pendingOperations.remove(operation);
//           }
//         } else if (operationType == 'delete') {
//           // For deletion, we don't need to check if the task exists locally
//           if (taskId.startsWith('temp_')) {
//             // If it's a temporary ID, it was never synced to Firestore
//             _pendingOperations.remove(operation);
//           } else {
//             await _deleteTaskFromFirestore(taskId);
//             _pendingOperations.remove(operation);
//           }
//         }
//       }
//
//       // Pull updates from Firestore
//       await _fetchTasksFromFirestore();
//
//       // Save current state
//       await _savePendingOperations();
//       await _saveLocalTasks();
//     } catch (e) {
//       print("Error syncing with Firestore: $e");
//     }
//   }
//
//   Future<void> _addTaskToFirestore(Task task) async {
//     final user = _auth.currentUser;
//     if (user == null) return;
//
//     try {
//       final docRef = await _firestore
//           .collection('users')
//           .doc(user.uid)
//           .collection('tasks')
//           .add(task.toFirestore());
//
//       // Update local task with Firestore ID and mark as synced
//       final index = _localTasks.indexWhere((t) => t.id == task.id);
//       if (index != -1) {
//         _localTasks[index].id = docRef.id;
//         _localTasks[index].isSynced = true;
//         await _saveLocalTasks();
//       }
//     } catch (e) {
//       print("Error adding task to Firestore: $e");
//       throw e;
//     }
//   }
//
//   Future<void> _updateTaskInFirestore(Task task) async {
//     final user = _auth.currentUser;
//     if (user == null) return;
//
//     // If this is a local-only task that hasn't been synced
//     if (task.id != null && task.id!.startsWith('temp_')) {
//       return _addTaskToFirestore(task);
//     }
//
//     try {
//       await _firestore
//           .collection('users')
//           .doc(user.uid)
//           .collection('tasks')
//           .doc(task.id)
//           .update(task.toFirestore());
//
//       // Mark task as synced
//       final index = _localTasks.indexWhere((t) => t.id == task.id);
//       if (index != -1) {
//         _localTasks[index].isSynced = true;
//         await _saveLocalTasks();
//       }
//     } catch (e) {
//       print("Error updating task in Firestore: $e");
//       throw e;
//     }
//   }
//
//   Future<void> _deleteTaskFromFirestore(String taskId) async {
//     final user = _auth.currentUser;
//     if (user == null) return;
//
//     // Skip if this is a local-only task that was never synced
//     if (taskId.startsWith('temp_')) return;
//
//     try {
//       await _firestore
//           .collection('users')
//           .doc(user.uid)
//           .collection('tasks')
//           .doc(taskId)
//           .delete();
//     } catch (e) {
//       print("Error deleting task from Firestore: $e");
//       throw e;
//     }
//   }
//
//   Future<void> _fetchTasksFromFirestore() async {
//     final user = _auth.currentUser;
//     if (user == null) return;
//
//     try {
//       final snapshot = await _firestore
//           .collection('users')
//           .doc(user.uid)
//           .collection('tasks')
//           .get();
//
//       final firestoreTasks = snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
//
//       // Merge Firestore and local tasks
//       for (final firestoreTask in firestoreTasks) {
//         // Find if we have this task locally
//         final localIndex = _localTasks.indexWhere((t) => t.id == firestoreTask.id);
//
//         if (localIndex == -1) {
//           // Task exists in Firestore but not locally - add it
//           _localTasks.add(firestoreTask);
//         } else {
//           // Task exists in both places - use the local version if it's not synced,
//           // otherwise use the Firestore version
//           if (_localTasks[localIndex].isSynced) {
//             _localTasks[localIndex] = firestoreTask;
//           }
//         }
//       }
//
//       await _saveLocalTasks();
//     } catch (e) {
//       print("Error fetching tasks from Firestore: $e");
//     }
//   }
//
//   void dispose() {
//     _tasksStreamController.close();
//   }
// }