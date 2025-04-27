import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressService {
  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ProgressService(this.userId);

  Future<Map<String, dynamic>> getProgressData() async {
    final tasksSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .get();

    final tasks = tasksSnapshot.docs
        .map((doc) => doc.data())
        .where((task) => task['isCompleted'] == true)
        .toList();

    // Streak Calculation
    final dates = tasks
        .map((t) => (t['createdAt'] as Timestamp).toDate())
        .toList();
    dates.sort();

    int currentStreak = 0;
    int longestStreak = 0;
    DateTime? prevDate;

    for (final date in dates.reversed) {
      if (prevDate == null ||
          prevDate.difference(date).inDays == 1 ||
          prevDate.difference(date).inDays == 0) {
        currentStreak++;
      } else {
        break;
      }
      prevDate = date;
      if (currentStreak > longestStreak) longestStreak = currentStreak;
    }

    // Category Distribution
    Map<String, int> categoryDistribution = {};
    for (var task in tasks) {
      final cat = task['category'] ?? 'Uncategorized';
      categoryDistribution[cat] = (categoryDistribution[cat] ?? 0) + 1;
    }

    // Achievements
    List<Map<String, dynamic>> achievements = [];
    if (currentStreak >= 5)
      achievements.add({'name': '5-Day Streak', 'icon': '🏆'});
    if (tasks.length >= 10)
      achievements.add({'name': 'Task Master', 'icon': '🎯'});
    if (tasks.length >= 50)
      achievements.add({'name': 'Productivity Guru', 'icon': '🚀'});

    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'categoryDistribution': categoryDistribution,
      'achievements': achievements,
    };
  }
}
