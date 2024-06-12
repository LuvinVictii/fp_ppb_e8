import 'package:cloud_firestore/cloud_firestore.dart';
// import 'lib/services/notes_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final CollectionReference users = FirebaseFirestore.instance.collection('users');
  final CollectionReference noteTags = FirebaseFirestore.instance.collection('note_tags');

  Future<void> addTag(List<String> tagList) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Check if the group already exists
      for (var tagName in tagList) {
        await tags.add({
          'tag_name': tagName,
          'timestamp': Timestamp.now(),
          'createdBy': user.uid,
        });
      }

    } else {
      throw Exception("No user logged in");
    }
  }

  Future<void> updateTag(String docID, List<String> newTags) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      for (String newTag in newTags) {
        await tags.doc(docID).update({
          'tag_name': newTag,
          'timestamp': Timestamp.now(),
        });
      }
    } else {
      throw Exception("No user logged in");
    }
  }


  Future<void> deleteTag(String tagID) async {
    return await tags
        .doc(tagID)
        .delete();
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
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return tags.where('createdBy', isEqualTo: user.uid).snapshots();
    } else {
      throw Exception("No user logged in");
    }
  }



  Future<List<String>> getTagsListString() async{
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot snapshot = await tags.where('createdBy', isEqualTo: user.uid).get();
      List<String> tagNames = snapshot.docs.map((doc) => doc['tag_name'] as String).toList();
      return tagNames;
    } else {
      throw Exception("No user logged in");
    }

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
