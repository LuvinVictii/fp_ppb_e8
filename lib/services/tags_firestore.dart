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
  final CollectionReference noteTags = FirebaseFirestore.instance.collection('note_tags');

  Future<void> addTag(String noteID, List<String> tagList) async {
    for (var tagName in tagList) {
      // Check if the tag already exists
      QuerySnapshot querySnapshot = await tags.where('tag_name', isEqualTo: tagName).get();
      String tagID;

      if (querySnapshot.docs.isEmpty) {
        // Add the tag if it doesn't exist and get the new tagID
        DocumentReference docRef = await tags.add({'tag_name': tagName});
        tagID = docRef.id;
      } else {
        // Get the existing tagID
        tagID = querySnapshot.docs.first.id;
      }

      // Add to note_tags
      await noteTags.add({
        'nt_note_id': noteID,
        'nt_tags_id': tagID
      });
    }
  }

  Future<void> updateTag(String noteID, List<String> newTagList) async {
    // Remove existing tags for the note
    QuerySnapshot noteTagSnapshot = await noteTags.where('nt_note_id', isEqualTo: noteID).get();
    for (var doc in noteTagSnapshot.docs) {
      await noteTags.doc(doc.id).delete();
    }

    // Add new tags
    await addTag(noteID, newTagList);
  }

  Future<void> deleteTag(String noteID, String tagID) async {
    // Remove the specific tag for the note
    QuerySnapshot querySnapshot = await noteTags
        .where('nt_note_id', isEqualTo: noteID)
        .where('nt_tags_id', isEqualTo: tagID)
        .get();

    for (var doc in querySnapshot.docs) {
      await noteTags.doc(doc.id).delete();
    }
  }

  Future<List<String>> getNoteTagsStream(String? noteID) async {
    var snapshot = await noteTags
        .where('nt_note_id', isEqualTo: noteID)
        .get();

    List<String> tagNames = [];
    for (var doc in snapshot.docs) {
      String tagID = doc['nt_tags_id'];
      DocumentSnapshot tagSnapshot = await tags.doc(tagID).get();
      if (tagSnapshot.exists) {
        tagNames.add(tagSnapshot['tag_name']);
      }
    }
    return tagNames;
  }





  Stream<QuerySnapshot> getTagsStream() {
    return tags.snapshots();
  }

  Future<QuerySnapshot> getByTags(List<String> searchedTags) async {
    return tags.where('tag_name', whereIn: searchedTags).get();
  }
}


  // Future<QuerySnapshot> getByTags(List<String> searchedTags) async {
  //   return tags.where('tag_list', arrayContainsAny: searchedTags).get();
  // }
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

// }
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
