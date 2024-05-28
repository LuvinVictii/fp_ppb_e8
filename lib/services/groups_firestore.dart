import 'package:cloud_firestore/cloud_firestore.dart';

class GroupService {
  final CollectionReference groups =
      FirebaseFirestore.instance.collection('groups');

  Future<void> addGroup(String group) {
    return groups.add({
      'group': group,
      'timestamp': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getGroupStream() {
    final groupsStream =
        groups.orderBy('timestamp', descending: true).snapshots();

    return groupsStream;
  }

  Future<void> updateGroup(String docID, String newGroup) {
    return groups.doc(docID).update({
      'group': newGroup,
      'timestamp': Timestamp.now(),
    });
  }

  Future<void> deleteGroup(String docID) {
    return groups.doc(docID).delete();
  }
}
