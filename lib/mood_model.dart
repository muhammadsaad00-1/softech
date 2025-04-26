import 'package:cloud_firestore/cloud_firestore.dart';

class MoodEntry {
  final String id;
  final String mood;
  final String? note;
  final DateTime date;
  final int? intensity; // 1-5 scale

  MoodEntry({
    required this.id,
    required this.mood,
    this.note,
    required this.date,
    this.intensity,
  });

  factory MoodEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MoodEntry(
      id: doc.id,
      mood: data['mood'],
      note: data['note'],
      date: (data['date'] as Timestamp).toDate(),
      intensity: data['intensity'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mood': mood,
      'note': note,
      'date': date,
      'intensity': intensity,
    };
  }
}