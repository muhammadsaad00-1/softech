import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'note_creation.dart';
import 'note_model.dart';
import 'note_card.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotesHome extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser;

  NotesHome({super.key});

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        body: Center(child: Text("Please log in.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Notes'),
        backgroundColor: Colors.orange[800],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange[800],
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NoteCreationScreen()),
          );
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('notes')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: Colors.orange));
          }
          final notes = snapshot.data!.docs
              .map((doc) => NoteModel.fromFirestore(doc))
              .toList();
          if (notes.isEmpty) {
            return Center(child: Text("No notes yet."));
          }
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, idx) => NoteCard(note: notes[idx]),
          );
        },
      ),
    );
  }
}
