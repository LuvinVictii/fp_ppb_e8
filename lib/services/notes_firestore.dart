import 'package:cloud_firestore/cloud_firestore.dart';

class NotesService {
  final CollectionReference notes =
      FirebaseFirestore.instance.collection('notes');

  Future<void> addNote(
      String title, String content, List<String> tags, String group) {
    return notes.add({
      'note_title': title,
      'note_content': content,
      'note_tags': tags,
      'note_group': group,
      'timestamp': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getNotesStream() {
    final notesStream =
        notes.orderBy('timestamp', descending: true).snapshots();

    return notesStream;
  }

  Future<void> updateNote(String docID, String title, String content,
      List<String> tags, String group) {
    return notes.doc(docID).update({
      'note_title': title,
      'note_content': content,
      'note_tags': tags,
      'note_group': group,
      'timestamp': Timestamp.now(),
    });
  }

  Future<void> deleteNote(String docID) {
    return notes.doc(docID).delete();
  }
}
