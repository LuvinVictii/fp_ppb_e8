import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fp_ppb_e8/services/groups_firestore.dart';
import 'package:flutter/material.dart';

class GroupListPage extends StatefulWidget {
  const GroupListPage({super.key});

  @override
  State<GroupListPage> createState() => _GroupListPageState();
}

class _GroupListPageState extends State<GroupListPage> {
  final GroupService firestoreService = GroupService();

  final TextEditingController textController = TextEditingController();

  void openGroupBox({String? docID}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: textController,
        ),
        actions: [
          ElevatedButton(
              onPressed: () {
                if (docID == null) {
                  firestoreService.addGroup(textController.text);
                } else {
                  firestoreService.updateGroup(docID, textController.text);
                }

                textController.clear();

                Navigator.pop(context);
              },
              child: const Text("Add"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Groups"),
        backgroundColor: Colors.lightBlue,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openGroupBox,
        backgroundColor: Colors.lightBlue,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getGroupStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List groupsList = snapshot.data!.docs;

            return ListView.builder(
                itemCount: groupsList.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot document = groupsList[index];
                  String docID = document.id;

                  Map<String, dynamic> data =
                      document.data() as Map<String, dynamic>;
                  String groupText = data['group'];

                  return ListTile(
                      title: Text(groupText),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          //update
                          IconButton(
                            onPressed: () => openGroupBox(docID: docID),
                            icon: const Icon(Icons.settings),
                          ),

                          //delete
                          IconButton(
                            onPressed: () =>
                                firestoreService.deleteGroup(docID),
                            icon: const Icon(Icons.delete),
                          ),
                        ],
                      ));
                });
          } else {
            return const Text("no groups..");
          }
        },
      ),
    );
  }

  text(String s) {}
}
