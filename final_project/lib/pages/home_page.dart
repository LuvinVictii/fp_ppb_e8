import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:final_project/services/firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService firestoreService = FirestoreService();
  final TextEditingController textController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser!;

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  void openNoteBox({String? docID}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: (docID == null)
            ? Text('Insert your note!', style: TextStyle(color: Colors.red[400]))
            : Text('Edit your note!', style: TextStyle(color: Colors.red[400])),
        backgroundColor: Colors.grey[900],
        content: TextField(
          controller: textController,
          style: TextStyle(color: Colors.red[400]),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[900],
            ),
            onPressed: () {
              if (docID == null) {
                firestoreService.addNote(textController.text);
              } else {
                firestoreService.updateNote(docID, textController.text);
              }
              textController.clear();
              Navigator.pop(context);
            },
            child: (docID == null)
                ? Text("Add", style: TextStyle(color: Colors.red[400]))
                : Text("Edit", style: TextStyle(color: Colors.red[400])),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Tugas Kedelapan',
          style: TextStyle(color: Colors.red[400]),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: signUserOut,
            icon: const Icon(Icons.logout, color: Colors.white),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openNoteBox(),
        backgroundColor: Colors.grey[900],
        child: Icon(
          Icons.add,
          color: Colors.red[400],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "LOGGED IN AS: ",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                Text(
                  user.email!,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestoreService.getNotesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List notesList = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: notesList.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot document = notesList[index];
                      String docID = document.id;
                      Map<String, dynamic> data =
                          document.data() as Map<String, dynamic>;
                      String noteText = data['note'];
                      String noteTime =
                          (data['timestamp'] as Timestamp).toDate().toString();
                      return ListTile(
                        title: Text(
                          noteText,
                          style: TextStyle(color: Colors.red[400], fontSize: 20.0),
                        ),
                        subtitle: Text(
                          noteTime,
                          style: TextStyle(color: Colors.red[400]),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => openNoteBox(docID: docID),
                              icon: Icon(Icons.settings, color: Colors.red[400]),
                            ),
                            IconButton(
                              onPressed: () => firestoreService.deleteNote(docID),
                              icon: Icon(Icons.delete, color: Colors.red[400]),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                } else {
                  return Center(
                    child: Text(
                      "At ${Timestamp.now()}, notes are not available..",
                      style: TextStyle(color: Colors.red[400], fontSize: 20.0),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
