import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String rawText;
  final List<String> summary;
  final DateTime createdAt;

  NoteModel({
    required this.id,
    required this.rawText,
    required this.summary,
    required this.createdAt,
  });

  factory NoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NoteModel(
      id: doc.id,
      rawText: data['rawText'] ?? '',
      summary: List<String>.from(data['summary'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
