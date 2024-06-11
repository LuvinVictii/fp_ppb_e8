import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:fp_ppb_e8/services/tags_firestore.dart';

class NotesService {
  final CollectionReference notes =
      FirebaseFirestore.instance.collection('notes');
  final TagService tagService = TagService();

  Future<void> addNote(String title, String content, List<String> tags,
      List<String> groups) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentReference docRef = await notes.add({
        'note_title': title,
        'note_content': content,
        'note_groups': groups,
        'created_by': user.uid,
        'timestamp': Timestamp.now(),
      });

      // Add tags to note
      await tagService.addTag(docRef.id, tags);
    } else {
      throw Exception("No user logged in");
    }
  }

  Future<void> updateNote(String docID, String title, String content,
      List<String> tags, List<String> groups) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await notes.doc(docID).update({
        'note_title': title,
        'note_content': content,
        'note_groups': groups,
        'timestamp': Timestamp.now(),
      });

      // Update tags for note
      await tagService.updateTag(docID, tags);
    } else {
      throw Exception("No user logged in");
    }
  }

  Future<void> deleteNote(String docID) async {
    await notes.doc(docID).delete();

    // Delete all tags associated with the note
    QuerySnapshot noteTagsSnapshot =
        await tagService.noteTags.where('nt_note_id', isEqualTo: docID).get();
    for (var doc in noteTagsSnapshot.docs) {
      await tagService.noteTags.doc(doc.id).delete();
    }
  }

  Stream<QuerySnapshot> getUserNotesStream(
      String userID, List<String> userGroups) {
    return notes.where('created_by', isEqualTo: userID).snapshots();
  }

  Stream<QuerySnapshot> getGroupNotesStream(List<String> userGroups) {
    return notes.where('note_groups', arrayContainsAny: userGroups).snapshots();
  }

  Stream<List<QueryDocumentSnapshot>> getUserAndGroupNotesStream(
      String userID, List<String> userGroups) {
    Stream<QuerySnapshot> userNotesStream =
        getUserNotesStream(userID, userGroups);

    if (userGroups.isEmpty) {
      return userNotesStream.map((userNotes) => userNotes.docs);
    }
    Stream<QuerySnapshot> groupNotesStream = getGroupNotesStream(userGroups);

    return Rx.combineLatest2(userNotesStream, groupNotesStream,
        (userNotes, groupNotes) {
      final allNotes = <QueryDocumentSnapshot>{};

      // Add user notes
      allNotes.addAll(userNotes.docs);

      // Add group notes, avoiding duplicates
      allNotes.addAll(groupNotes.docs
          .where((groupNote) => groupNote['created_by'] != userID));

      return allNotes.toList();
    });
  }
}
