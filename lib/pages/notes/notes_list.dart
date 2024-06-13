import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
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
  Color mainBackgroundColor = Colors.white;
  Color mainAppBarBackgroundColor = Colors.deepPurple;
  Color mainAppBarTextColor = Colors.white;
  Color mainIconColor = Colors.deepPurple;
  Color dialogBackgroundColor = Colors.white;
  Color dialogTextColor = Colors.black;
  Color loadingIndicatorColor = Colors.deepPurple;
  Color listItemBackgroundColor = Colors.white;

  late bool isLightMode = true;

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
          backgroundColor: dialogBackgroundColor,
          titleTextStyle: TextStyle(color: dialogTextColor),
          contentTextStyle: TextStyle(color: dialogTextColor),
          title: Text(docID == null ? 'Add Note' : 'Edit Note'),
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
                  title: Text(
                    'Tags',
                    style: TextStyle(
                      color: mainAppBarBackgroundColor,
                    ),
                  ),
                  selectedColor: mainAppBarBackgroundColor,
                  unselectedColor: mainAppBarBackgroundColor,
                  checkColor: mainAppBarBackgroundColor,
                  backgroundColor: mainBackgroundColor,
                  itemsTextStyle: TextStyle(
                      color: mainAppBarBackgroundColor,
                    ),
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
                  title: Text("Groups",
                          style: TextStyle(
                          color: mainAppBarBackgroundColor,
                        ),
                      ),
                  selectedColor: mainAppBarBackgroundColor,
                  unselectedColor: mainAppBarBackgroundColor,
                  checkColor: mainAppBarBackgroundColor,
                  backgroundColor: mainBackgroundColor,
                  itemsTextStyle: TextStyle(
                    color: mainAppBarBackgroundColor,
                  ),
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
              child: Text(
                "Cancel",
                style: TextStyle(color: dialogTextColor),
              ),
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
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(mainBackgroundColor),
              ),
              child: Text(
                "Save",
                style: TextStyle(color: dialogTextColor),
              ),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mainBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Notes',
          style: TextStyle(
            color: mainAppBarTextColor,
          ),
        ),
        backgroundColor: mainAppBarBackgroundColor,
          actions: [
            IconButton(
            onPressed: () {
              setState(() {
              isLightMode = !isLightMode;
              if (!isLightMode) {
                mainBackgroundColor = Colors.grey.shade900;
                mainAppBarBackgroundColor = const Color(0xFF8AB73A);
                mainAppBarTextColor = Colors.grey.shade900;
                mainIconColor = const Color(0xFF8AB73A);
                dialogBackgroundColor = Colors.grey.shade800;
                dialogTextColor = Colors.white;
                loadingIndicatorColor = const Color(0xFF8AB73A);
                listItemBackgroundColor = Colors.grey.shade800;
              } else {
                mainBackgroundColor = Colors.white;
                mainAppBarBackgroundColor = Colors.deepPurple;
                mainAppBarTextColor = Colors.white;
                mainIconColor = Colors.deepPurple;
                dialogBackgroundColor = Colors.white;
                dialogTextColor = Colors.black;
                loadingIndicatorColor = Colors.deepPurple;
                listItemBackgroundColor = Colors.white;
              }
              });
              },
              icon: Icon(
            isLightMode ? Icons.light_mode : Icons.dark_mode,
            color: mainAppBarTextColor,
          ),
        )]
        ,leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu, color: mainAppBarTextColor),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: Drawer(
        backgroundColor: mainBackgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: mainAppBarBackgroundColor,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: mainAppBarTextColor,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: Text(
                'Groups',
                style: TextStyle(
                  color: dialogTextColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupListPage(
                      mainBackgroundColor: mainBackgroundColor,
                      mainAppBarBackgroundColor: mainAppBarBackgroundColor,
                      mainAppBarTextColor: mainAppBarTextColor,
                      mainIconColor: mainIconColor,
                      dialogBackgroundColor: dialogBackgroundColor,
                      dialogTextColor: dialogTextColor,
                      loadingIndicatorColor: loadingIndicatorColor,
                      listItemBackgroundColor: listItemBackgroundColor,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              title: Text(
                'Tags',
                style: TextStyle(
                  color: dialogTextColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TagListPage(
                      mainBackgroundColor: mainBackgroundColor,
                      mainAppBarBackgroundColor: mainAppBarBackgroundColor,
                      mainAppBarTextColor: mainAppBarTextColor,
                      mainIconColor: mainIconColor,
                      dialogBackgroundColor: dialogBackgroundColor,
                      dialogTextColor: dialogTextColor,
                      loadingIndicatorColor: loadingIndicatorColor,
                      listItemBackgroundColor: listItemBackgroundColor,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openNoteBox(),
        backgroundColor: mainAppBarBackgroundColor,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by title',
                      labelStyle: TextStyle(color: mainIconColor),
                      prefixIcon: Icon(Icons.search, color: mainIconColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: mainIconColor), // Change border color here
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: mainIconColor), // Change focused border color here
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),

                IconButton(

                  icon: Icon(Icons.filter_list, color: mainIconColor),
                  onPressed: () {
                    showModalBottomSheet(

                      backgroundColor: dialogBackgroundColor,
                      context: context,

                      builder: (context) {

                        return Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Filter",
                                style: TextStyle(
                                  color: dialogTextColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Filter by Tags",
                                  style: TextStyle(
                                    color: dialogTextColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              MultiSelectDialogField(
                                items: noteTags.map((tag) => MultiSelectItem<String>(tag, tag)).toList(),
                                title: Text(
                                  'Tags',
                                  style: TextStyle(
                                    color: mainAppBarBackgroundColor,
                                  ),
                                ),
                                selectedColor: mainAppBarBackgroundColor,
                                unselectedColor: mainAppBarBackgroundColor,
                                checkColor: mainAppBarBackgroundColor,
                                backgroundColor: mainBackgroundColor,
                                itemsTextStyle: TextStyle(
                                  color: mainAppBarBackgroundColor,
                                ),
                                onConfirm: (results) {
                                  setState(() {
                                    selectedTags = results.cast<String>();
                                  });
                                },
                                initialValue: selectedTags,
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Filter by Groups",
                                  style: TextStyle(
                                    color: dialogTextColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              MultiSelectDialogField(
                                items: groupsUser.map((group) => MultiSelectItem<String>(group, group)).toList(),
                                title: Text(
                                  'Groups',
                                  style: TextStyle(
                                    color: mainAppBarBackgroundColor,
                                  ),
                                ),
                                selectedColor: mainAppBarBackgroundColor,
                                unselectedColor: mainAppBarBackgroundColor,
                                checkColor: mainAppBarBackgroundColor,
                                backgroundColor: mainBackgroundColor,
                                itemsTextStyle: TextStyle(
                                  color: mainAppBarBackgroundColor,
                                ),
                                onConfirm: (results) {
                                  setState(() {
                                    selectedTags = results.cast<String>();
                                  });
                                },
                                initialValue: selectedGroups,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: firestoreService.getUserAndGroupNotesStream(
                  currentUser?.uid ?? '', groupsUser),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(
                    color: loadingIndicatorColor,
                  ));
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
                            return Center(
                              child: CircularProgressIndicator(
                                color: loadingIndicatorColor,
                              ),
                            );
                          } else {
                            List<String> noteTags =
                            List<String>.from(data['note_tags'] ?? []);
                            List<String> noteGroups =
                            List<String>.from(data['note_groups'] ?? []);

                            return Card(
                              color: listItemBackgroundColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 4,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                title: Text(
                                  noteTitle,
                                  style: TextStyle(fontWeight: FontWeight.bold, color:dialogTextColor),
                                ),
                                subtitle: Text(noteContent,
                                  style: TextStyle(fontWeight: FontWeight.bold, color:dialogTextColor),
                                ),
                                trailing: currentUser!.uid == noteCreatedBy
                                    ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () =>
                                          openNoteBox(docID: docID),
                                      icon: Icon(
                                        Icons.edit,
                                        color: mainIconColor,
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
                                      backgroundColor: dialogBackgroundColor,
                                      title: Text(
                                        noteTitle,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,color:mainAppBarBackgroundColor),

                                      ),
                                      content: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text("Content: $noteContent",
                                            style: TextStyle(
                                                color:dialogTextColor),
                                          ),
                                          const SizedBox(height: 8),
                                          Text("Tags: ${noteTags.join(', ')}",
                                            style: TextStyle(
                                                color:dialogTextColor),
                                          ),
                                          const SizedBox(height: 8),
                                          Text("Groups: ${noteGroups.join(', ')}",
                                            style: TextStyle(
                                                color:dialogTextColor),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text("Close",
                                            style: TextStyle(
                                                color:dialogTextColor),
                                          ),
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
