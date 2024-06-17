import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupService {
  final CollectionReference groups =
      FirebaseFirestore.instance.collection('groups');
  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference notes =
      FirebaseFirestore.instance.collection('notes');

  Future<void> addGroup(String group) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Check if the group already exists
      QuerySnapshot querySnapshot =
          await groups.where('group', isEqualTo: group).get();
      if (querySnapshot.docs.isNotEmpty) {
        // If a group with the same name exists, throw an error
        throw Exception("Group with the same name already exists");
      } else {
        // If the group does not exist, add it to Firestore
        await groups.add({
          'group': group,
          'timestamp': Timestamp.now(),
          'createdBy': user.uid,
          'members': [user.uid],
        });
      }
    } else {
      throw Exception("No user logged in");
    }
  }

  Stream<QuerySnapshot> getGroupStream() {
    return groups.orderBy('timestamp', descending: true).snapshots();
  }

  Future<void> updateGroup(String docID, String newGroup) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetch the current group document using docID
      final groupDoc = await groups.doc(docID).get();
      if (groupDoc.exists) {
        // Cast the data to a Map<String, dynamic>
        final data = groupDoc.data() as Map<String, dynamic>;
        final oldGroup = data['group'];

        // Start a Firestore batch write
        final batch = FirebaseFirestore.instance.batch();

        // Update the group document
        batch.update(groupDoc.reference, {
          'group': newGroup,
          'timestamp': Timestamp.now(),
        });

        // Get all notes that contain the old group name in the note_groups array
        final notesSnapshot = await FirebaseFirestore.instance
            .collection('notes')
            .where('note_groups', arrayContains: oldGroup)
            .get();

        // Update each note to replace the old group name with the new group name
        for (var noteDoc in notesSnapshot.docs) {
          List<dynamic> noteGroups = noteDoc.data()['note_groups'];
          int index = noteGroups.indexOf(oldGroup);
          if (index != -1) {
            noteGroups[index] = newGroup;
          }
          batch.update(noteDoc.reference, {'note_groups': noteGroups});
        }

        // Commit the batch write
        await batch.commit();
      } else {
        throw Exception("Group not found");
      }
    } else {
      throw Exception("No user logged in");
    }
  }

  Future<void> deleteGroup(String docID) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetch the current group document using docID
      final groupDoc = await groups.doc(docID).get();
      if (groupDoc.exists) {
        // Cast the data to a Map<String, dynamic>
        final data = groupDoc.data() as Map<String, dynamic>;
        final groupName = data['group'];

        // Start a Firestore batch write
        final batch = FirebaseFirestore.instance.batch();

        // Get all notes that contain the group name in the note_groups array
        final notesSnapshot = await FirebaseFirestore.instance
            .collection('notes')
            .where('note_groups', arrayContains: groupName)
            .get();

        // Remove the group name from each note's note_groups array
        for (var noteDoc in notesSnapshot.docs) {
          List<dynamic> noteGroups = noteDoc.data()['note_groups'];
          noteGroups.remove(groupName);
          batch.update(noteDoc.reference, {'note_groups': noteGroups});
        }

        // Delete the group document
        batch.delete(groupDoc.reference);

        // Commit the batch write
        await batch.commit();
      } else {
        throw Exception("Group not found");
      }
    } else {
      throw Exception("No user logged in");
    }
  }

  Future<void> joinGroup(String docID) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return groups.doc(docID).update({
        'members': FieldValue.arrayUnion([user.uid]),
      });
    } else {
      throw Exception("No user logged in");
    }
  }

  Future<void> leaveGroup(String docID) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return groups.doc(docID).update({
        'members': FieldValue.arrayRemove([user.uid]),
      });
    } else {
      throw Exception("No user logged in");
    }
  }
}
