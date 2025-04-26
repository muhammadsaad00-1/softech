import 'package:flutter/material.dart';
import 'note_model.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;
  const NoteCard({required this.note, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.summary.isNotEmpty) ...[
              Text("Summary:",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.orange[800])),
              SizedBox(height: 8),
              ...note.summary.map((point) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("• ", style: TextStyle(color: Colors.orange)),
                  Expanded(child: Text(point)),
                ],
              )),
              Divider(),
            ],
            Text(
              note.rawText,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
