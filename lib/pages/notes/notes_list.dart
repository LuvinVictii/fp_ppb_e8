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
  final TextEditingController groupController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  User? currentUser;
  List<String> userGroups = [];
  List<String> groupsUser = [];
  List<MultiSelectItem<String>> tagItems = [];
  List<String> selectedTags = [];
  List<String> selectedGroups = [];
  List<String> noteTags = [];

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    fetchUserGroups();
    fetchGroupsUser();
    fetchTags();
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   currentUser = FirebaseAuth.instance.currentUser;
  //   fetchUserGroups();
  //   fetchGroupsUser();
  //   fetchTags();
  // }

  Future<void> fetchUserGroups() async {
    if (currentUser != null) {
      QuerySnapshot groupSnapshot = await firestoreGroupService.groups
          .where('createdBy', isEqualTo: currentUser!.uid)
          .get();
      setState(() {
        userGroups = groupSnapshot.docs.map((doc) {
          Map<String, dynamic> groupData = doc.data() as Map<String, dynamic>;
          return groupData['group'].toString();
        }).toList();
      });
    }
  }

  Future<void> fetchGroupsUser() async {
    if (currentUser != null) {
      QuerySnapshot groupSnapshot = await firestoreGroupService.groups
          .where('members', arrayContains: currentUser!.uid)
          .get();
      setState(() {
        groupsUser = groupSnapshot.docs.map((doc) {
          Map<String, dynamic> dataGroup = doc.data() as Map<String, dynamic>;
          return dataGroup['group'].toString();
        }).toList();
      });
    }
  }

  Future<void> fetchTags() async {
    // QuerySnapshot tagSnapshot = await firestoreTagsService.tags.get();
    List <String> temp = await firestoreTagsService.getTagsListString();
    if (currentUser != null) {
      setState((){
        noteTags = temp;
      });
    }
  }

  void openNoteBox({String? docID}) async {
    await fetchUserGroups();
    await fetchGroupsUser();
    await fetchTags();


    if (docID != null) {
      DocumentSnapshot document = await firestoreService.notes.doc(docID).get();
      if (document.exists) {
        Map<String, dynamic> data = document.data() as Map<String, dynamic>;
        titleController.text = data['note_title'];
        contentController.text = data['note_content'];
        selectedTags = List<String>.from(data['note_tags'] ?? []);
        groupController.text = data['note_groups'].join(', ');
      }
    } else {
      titleController.clear();
      contentController.clear();
      selectedTags.clear();
      groupController.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: "Title",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: "Content",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 12),
                MultiSelectDialogField(
                  items: noteTags.map((tag) => MultiSelectItem<String>(tag, tag)).toList(),
                  initialValue: selectedTags,
                  title: const Text("Tags"),
                  selectedColor: Colors.deepPurple,
                  onConfirm: (results) {
                    setState(() {
                      selectedTags = results.cast<String>();
                    });
                  },
                ),
                const SizedBox(height: 12),
                MultiSelectDialogField(
                  items: userGroups.map((group) => MultiSelectItem<String>(group, group)).toList(),
                  initialValue: groupController.text.split(',').map((e) => e.trim()).toList(),
                  title: const Text("Groups"),
                  selectedColor: Colors.deepPurple,
                  onConfirm: (results) {
                    setState(() {
                      groupController.text = results.map((e) => e.toString()).join(', ');
                    });
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
                List<String> groups = groupController.text.split(',').map((group) => group.trim()).toList();

                if (docID == null) {
                  firestoreService.addNote(
                    titleController.text,
                    contentController.text,
                    selectedTags,
                    groups,
                  );
                } else {
                  firestoreService.updateNote(
                    docID,
                    titleController.text,
                    contentController.text,
                    selectedTags,
                    groups,
                  );
                }

                titleController.clear();
                contentController.clear();
                selectedTags.clear();
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search by title',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0,vertical: 6.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Filter by Tags"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: MultiSelectDialogField(
              items: noteTags.map((tag) => MultiSelectItem<String>(tag, tag)).toList(),
              title: const Text("Filter by Tags"),
              selectedColor: Colors.deepPurple,
              onConfirm: (results) {
                setState(() {
                  selectedTags = results.cast<String>();
                });
              },
              chipDisplay: MultiSelectChipDisplay(
                onTap: (value) {
                  setState(() {
                    selectedTags.remove(value);
                  });
                },
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0,vertical: 6.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Filter by Groups"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: MultiSelectDialogField(
              items: userGroups.map((group) => MultiSelectItem<String>(group, group)).toList(),
              title: const Text("Filter by Groups"),
              selectedColor: Colors.deepPurple,
              onConfirm: (results) {
                setState(() {
                  selectedGroups = results.cast<String>();
                });
              },
              chipDisplay: MultiSelectChipDisplay(
                onTap: (value) {
                  setState(() {
                    selectedGroups.remove(value);
                  });
                },
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: firestoreService.getUserAndGroupNotesStream(
                  currentUser?.uid ?? '', groupsUser),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text("Error loading notes"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No notes found"));
                } else {
                  List<DocumentSnapshot> userNotes = snapshot.data!;

                  // Filter notes by search query
                  userNotes = userNotes.where((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    String noteTitle = data['note_title'];
                    return noteTitle.toLowerCase().contains(searchController.text.toLowerCase());
                  }).toList();

                  // Filter notes by selected tags and groups
                  if (selectedTags.isNotEmpty) {
                    userNotes = userNotes.where((doc) {
                      List<String> noteTags = List<String>.from((doc.data() as Map<String, dynamic>)['note_tags'] ?? []);
                      return selectedTags.any((tag) => noteTags.contains(tag));
                    }).toList();
                  }

                  if (selectedGroups.isNotEmpty) {
                    userNotes = userNotes.where((doc) {
                      List<String> noteGroups = List<String>.from((doc.data() as Map<String, dynamic>)['note_groups'] ?? []);
                      return selectedGroups.any((group) => noteGroups.contains(group));
                    }).toList();
                  }

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
                      String noteCreatedBy = data['created_by'];

                      return FutureBuilder<List<String>>(
                        future: firestoreTagsService.getNoteTagsStream(document.id),
                        builder: (context, tagSnapshot) {
                          if (tagSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else {
                            List<String> noteTags =
                            List<String>.from(data['note_tags'] ?? []);
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
                                trailing: currentUser!.uid == noteCreatedBy
                                    ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () =>
                                          openNoteBox(docID: docID),
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
                                )
                                    : null,
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
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
