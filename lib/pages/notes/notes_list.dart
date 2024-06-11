import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart'; // Import the multi_select_flutter package
import 'package:fp_ppb_e8/services/groups_firestore.dart';
import 'package:fp_ppb_e8/services/notes_firestore.dart';
import 'package:fp_ppb_e8/services/tags_firestore.dart';
import 'package:fp_ppb_e8/pages/groups/groups_list.dart';
import 'package:fp_ppb_e8/pages/tags/tags_list.dart';

class NotesListPage extends StatefulWidget {
  const NotesListPage({Key? key}) : super(key: key);

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  final NotesService firestoreService = NotesService();
  final TagService firestoreTagsService = TagService();
  final GroupService firestoreGroupService = GroupService();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();
  final TextEditingController groupController = TextEditingController();

  User? currentUser;
  List<String> userGroups = [];

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    fetchUserGroups();
  }

  Future<void> fetchUserGroups() async {
    if (currentUser != null) {
      QuerySnapshot groupSnapshot = await firestoreGroupService.groups
          .where('members', arrayContains: currentUser!.uid)
          .get();
      setState(() {
        userGroups = groupSnapshot.docs.map((doc) {
          Map<String, dynamic> groupData = doc.data() as Map<String, dynamic>;
          return groupData['group'].toString();
        }).toList();
      });
    }
  }

  void openNoteBox({String? docID}) async {
    if (docID != null) {
      DocumentSnapshot document = await firestoreService.notes.doc(docID).get();
      if (document.exists) {
        Map<String, dynamic> data = document.data() as Map<String, dynamic>;
        List<String>? noteTags =
            await firestoreTagsService.getNoteTagsStream(docID);
        titleController.text = data['note_title'];
        contentController.text = data['note_content'];
        tagsController.text = noteTags.join(', ');
        groupController.text = data['note_groups'].join(', ');
      }
    } else {
      titleController.clear();
      contentController.clear();
      tagsController.clear();
      groupController.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: "Title",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: "Content",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tagsController,
                  decoration: InputDecoration(
                    labelText: "Tags (comma separated)",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                MultiSelectDialogField(
                  items: userGroups
                      .map((group) => MultiSelectItem(group, group))
                      .toList(),
                  initialValue: groupController.text
                      .split(',')
                      .map((e) => e.trim())
                      .toList(),
                  title: const Text("Groups"),
                  selectedColor: Colors.deepPurple,
                  onConfirm: (results) {
                    groupController.text =
                        results.map((e) => e.toString()).join(', ');
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                List<String> tags = tagsController.text
                    .split(',')
                    .map((tag) => tag.trim())
                    .toList();
                List<String> groups = groupController.text
                    .split(',')
                    .map((group) => group.trim())
                    .toList();

                if (docID == null) {
                  firestoreService.addNote(
                    titleController.text,
                    contentController.text,
                    tags,
                    groups,
                  );
                } else {
                  firestoreService.updateNote(
                    docID,
                    titleController.text,
                    contentController.text,
                    tags,
                    groups,
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notes"),
        backgroundColor: Colors.deepPurple,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurple,
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
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const GroupListPage()),
                );
              },
            ),
            ListTile(
              title: const Text('Tags'),
              onTap: () {
                Navigator.pop(context);
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
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getUserNotesStream(
            currentUser?.uid ?? '', userGroups),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<DocumentSnapshot> userNotes = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: userNotes.length,
              itemBuilder: (context, index) {
                DocumentSnapshot document = userNotes[index];
                String docID = document.id;

                Map<String, dynamic> data =
                    document.data() as Map<String, dynamic>;
                String noteTitle = data['note_title'];
                String noteContent = data['note_content'];

                return FutureBuilder<List<String>>(
                  future: firestoreTagsService.getNoteTagsStream(document.id),
                  builder: (context, tagSnapshot) {
                    if (tagSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else {
                      List<String> noteTags = tagSnapshot.data ?? [];
                      List<String> noteGroups =
                          List<String>.from(data['note_groups'] ?? []);

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 4,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Text(
                            noteTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(noteContent),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => openNoteBox(docID: docID),
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    firestoreService.deleteNote(docID),
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                title: Text(
                                  noteTitle,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                content: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("Content: $noteContent"),
                                    const SizedBox(height: 8),
                                    Text("Tags: ${noteTags.join(', ')}"),
                                    const SizedBox(height: 8),
                                    Text("Groups: ${noteGroups.join(', ')}"),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Close"),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    }
                  },
                );
              },
            );
          } else {
            return const Center(child: Text("No notes found"));
          }
        },
      ),
    );
  }
}
