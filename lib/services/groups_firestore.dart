import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupService {
  final CollectionReference groups =
      FirebaseFirestore.instance.collection('groups');
  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');

  Future<void> addGroup(String group) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return groups.add({
        'group': group,
        'timestamp': Timestamp.now(),
        'createdBy': user.uid,
        'members': [user.uid],
      });
    } else {
      throw Exception("No user logged in");
    }
  }

  Stream<QuerySnapshot> getGroupStream() {
    return groups.orderBy('timestamp', descending: true).snapshots();
  }

  Future<void> updateGroup(String docID, String newGroup) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return groups.doc(docID).update({
        'group': newGroup,
        'timestamp': Timestamp.now(),
      });
    } else {
      throw Exception("No user logged in");
    }
  }

  Future<void> deleteGroup(String docID) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return groups.doc(docID).delete();
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
