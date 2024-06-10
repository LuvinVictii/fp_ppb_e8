import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fp_ppb_e8/services/notes_firestore.dart';
import 'package:fp_ppb_e8/services/tags_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fp_ppb_e8/pages/groups/groups_list.dart';
import 'package:fp_ppb_e8/pages/tags/tags_list.dart';

class NotesListPage extends StatefulWidget {
  const NotesListPage({super.key});

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  final NotesService firestoreService = NotesService();
  final TagService firestoreTagsService = TagService();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();
  final TextEditingController groupController = TextEditingController();

  void openNoteBox({String? docID}) async {
    if (docID != null) {
      // Prefill the text controllers with the existing data
      DocumentSnapshot document = await firestoreService.notes.doc(docID).get();
      if (document.exists) {
        Map<String, dynamic> data = document.data() as Map<String, dynamic>;
        List<String>? noteTags = await firestoreTagsService.getNoteTagsStream(docID);
        titleController.text = data['note_title'];
        contentController.text = data['note_content'];
        tagsController.text = noteTags.join(', ');
        groupController.text = data['note_group'];
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: "Content"),
              ),
              TextField(
                controller: tagsController,
                decoration: const InputDecoration(labelText: "Tags (comma separated)"),
              ),
              TextField(
                controller: groupController,
                decoration: const InputDecoration(labelText: "Group"),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              List<String> tags = tagsController.text
                  .split(',')
                  .map((tag) => tag.trim())
                  .toList();

              if (docID == null) {
                firestoreService.addNote(
                  titleController.text,
                  contentController.text,
                  tags,
                  groupController.text,
                );
              } else {
                firestoreService.updateNote(
                  docID,
                  titleController.text,
                  contentController.text,
                  tags,
                  groupController.text,
                );
              }

              titleController.clear();
              contentController.clear();
              tagsController.clear();
              groupController.clear();

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notes"),
        backgroundColor: Colors.lightBlue,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.lightBlue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('Groups'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GroupListPage()),
                );
              },
            ),
            ListTile(
              title: const Text('Tags'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TagListPage()),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openNoteBox(),
        backgroundColor: Colors.lightBlue,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getNotesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<DocumentSnapshot> notesList = snapshot.data!.docs;

            return ListView.builder(
              itemCount: notesList.length,
              itemBuilder: (context, index) {
                DocumentSnapshot document = notesList[index];
                String docID = document.id;

                Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                String noteTitle = data['note_title'];
                String noteContent = data['note_content'];

                return FutureBuilder<List<String>>(
                  future: firestoreTagsService.getNoteTagsStream(document.id),
                  builder: (context, tagSnapshot) {
                    if (tagSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.blue,),
                      );
                    } else {
                      List<String> noteTags = tagSnapshot.data ?? [];
                      String noteGroup = data['note_group'];

                      return ListTile(
                        title: Text(noteTitle),
                        subtitle: Text(noteContent),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Update
                            IconButton(
                              onPressed: () => openNoteBox(docID: docID),
                              icon: const Icon(Icons.edit),
                            ),
                            // Delete
                            IconButton(
                              onPressed: () => firestoreService.deleteNote(docID),
                              icon: const Icon(Icons.delete),
                            ),
                          ],
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(noteTitle),
                              content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("Content: $noteContent"),
                                  Text("Tags: ${noteTags.join(', ')}"),
                                  Text("Group: $noteGroup"),
                                ],
                              ),
                              actions: [
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Close"),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }
                  },
                );
              },
            );
          } else {
            return const Center(child: Text("No notes.."));
          }
        },
      ),


      // bottomNavigationBar: BottomAppBar(
      //   child: Row(
      //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      //     children: [
      //       ElevatedButton(
      //         onPressed: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => GroupListPage()),
      //           );
      //         },
      //         child: Text("Group List"),
      //       ),
      //       ElevatedButton(
      //         onPressed: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => TagListPage()),
      //           );
      //         },
      //         child: Text("Tag List"),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }
}
