import 'package:cloud_firestore/cloud_firestore.dart';
// import 'lib/services/notes_firestore.dart';

class Tags {
  final List<String> tagList;

  Tags({required this.tagList});

  Map<String, dynamic> toMap() {
    return {
      'tag_list': tagList.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList(),
    };
  }
}




class TagService {
  final CollectionReference tags = FirebaseFirestore.instance.collection('tags');

  Future <void> addTag(List<String> tagList){
    return tags.add(Tags(tagList: tagList).toMap());
  }

  Future <void> updateTag(String tagID, List<String> newTagList){
    return tags.doc(tagID).update(Tags(tagList: newTagList).toMap());
  }

  Future <void> deleteTag(String tagID) {
    return tags.doc(tagID).delete();
  }

  Stream<QuerySnapshot> getTagsStream() {
    return tags.orderBy('tag_list', descending: true).snapshots();
  }

  Future<QuerySnapshot> getByTags(List<String> searchedTags) async {
    return tags.where('tag_list', arrayContainsAny: searchedTags).get();
  }
  // Future<List<QueryDocumentSnapshot<Object?>>> getByTags(List<String> searchedTags) async {
  //   QuerySnapshot<Object?> currentTags =
  //   await tags.where('tag_list', arrayContainsAny: searchedTags).get();
  //   QuerySnapshot<Object?>  filteredTags;
  //   for (var tag in currentTags.docs) {
  //     bool containsAllTags = true;
  //     for (var searchedTag in searchedTags) {
  //       if (!tag['tag_list'].contains(searchedTag)) {
  //         containsAllTags = false;
  //         break;
  //       }
  //     }
  //     if (containsAllTags) {
  //       filteredTags.add(tag);
  //     }
  //   }
  //   return filteredTags;
  // }





  // Future<List<String>> getIDByTags(List<String> searchedTags) async {
  //   List<String> tagIDs = [];
  //   QuerySnapshot querySnapshot = await tags.where('tag_list', arrayContainsAny: searchedTags).get();
  //   for (var doc in querySnapshot.docs) {
  //     tagIDs.add(doc.id);
  //   }
  //   return tagIDs;
  // }

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
