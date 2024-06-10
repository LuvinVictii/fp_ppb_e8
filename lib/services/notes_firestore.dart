import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fp_ppb_e8/services/tags_firestore.dart';

class NotesService {
  final CollectionReference notes =
  FirebaseFirestore.instance.collection('notes');
  final TagService tagService = TagService(); // Instantiate TagService

  Future<void> addNote(
      String title, String content, List<String> tags, String group) async {
    DocumentReference docRef = await notes.add({
      'note_title': title,
      'note_content': content,
      'note_tags': tags,
      'note_group': group,
      'timestamp': Timestamp.now(),
    });

    // Add tags to note
    await tagService.addTag(docRef.id, tags);
  }

  Future<void> updateNote(String docID, String title, String content,
      List<String> tags, String group) async {
    await notes.doc(docID).update({
      'note_title': title,
      'note_content': content,
      'note_tags': tags,
      'note_group': group,
      'timestamp': Timestamp.now(),
    });

    // Update tags for note
    await tagService.updateTag(docID, tags);
  }

  Future<void> deleteNote(String docID) async {
    await notes.doc(docID).delete();

    // Delete all tags associated with the note
    QuerySnapshot noteTagsSnapshot = await tagService.noteTags.where('nt_note_id', isEqualTo: docID).get();
    for (var doc in noteTagsSnapshot.docs) {
      await tagService.noteTags.doc(doc.id).delete();
    }
  }

  Stream<QuerySnapshot> getNotesStream() {
    return notes.orderBy('timestamp', descending: true).snapshots();
  }
}
