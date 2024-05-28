import 'package:cloud_firestore/cloud_firestore.dart';
// import 'lib/services/notes_firestore.dart';

class Tags {
  List<String> tagList;

  Tags({required this.tagList});

  Map<String, dynamic> toMap() {
    return {
      'tag_list': tagList,
    };
  }
}



class FirestoreService {
  final CollectionReference tags = FirebaseFirestore.instance.collection('tags');

  Future <void> addTag(List<String> tagList) async {
    await tags.add(Tags(tagList: tagList).toMap());
  }

  Future <void> updateTag(String tagID, List<String> newTagList) {
    tags.doc(tagID).delete();
    return tags.add(Tags(tagList: newTagList).toMap());
  }

  Future <void> deleteTag(String tagID) {
    return tags.doc(tagID).delete();
  }
}
/*
  Future<void> addNoteWithTags(String note, List<String> tagsList) async {
    DocumentReference noteRef = await notes.add({
      'note': note,
      'timestamp': Timestamp.now(),
    });
    for (String tag in tagsList) {
      await tags.add({
        'noteId': noteRef.id,
        'tag': tag,
      });
    }
  }

  Future<void> addTagsToNote(String docID, List<String> tagsList) async {
    for (String tag in tagsList) {
      await tags.add({
        'noteId': docID,
        'tag': tag,
      });
    }
  }

  Future <void> updateNoteWithTags(String docID, String newNote, List<String> newTagsList) async {
    await notes.doc(docID).update(
        {
          'note': newNote,
          'timestamp': Timestamp.now(),
        }
    );
    QuerySnapshot oldTags = await tags.where('noteId', isEqualTo: docID).get();
    for (QueryDocumentSnapshot doc in oldTags.docs) {
      await doc.reference.delete();
    }

    for (String tag in newTagsList) {
      await tags.add({
        'noteId': docID,
        'tag': tag,
      });
    }
  }

    Future <void> updateTagsToNote(String docID, List<String> newTagsList) async {
    QuerySnapshot oldTags = await tags.where('noteId', isEqualTo: docID).get();
    for (QueryDocumentSnapshot doc in oldTags.docs) {
      await doc.reference.delete();
    }
    
    for (String tag in newTagsList) {
      await tags.add({
        'noteId': docID,
        'tag': tag,
      });
    }
  }

  Future<void> deleteNoteWithTags(String docID) async {
    await notes.doc(docID).delete();

    QuerySnapshot noteTags = await tags.where('noteId', isEqualTo: docID).get();
    for (QueryDocumentSnapshot doc in noteTags.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> deleteTagsFromNote(String docID, List<String> newTagsList) async {
    QuerySnapshot oldTagsSnapshot = await tags.where('noteId', isEqualTo: docID).get();
    for (var doc in oldTagsSnapshot.docs) {
      String oldTag = doc['tag'];
      if (newTagsList.contains(oldTag)) {
        await doc.reference.delete();
      }
    }
  }

  Future<List<String>> getTagsForNoteId(String noteId) async {
    QuerySnapshot tagSnapshot = await tags.where('noteId', isEqualTo: noteId).get();
    return tagSnapshot.docs.map((doc) => doc['tag'] as String).toList();
  }
}
*/
