import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fp_ppb_e8/services/groups_firestore.dart';

class GroupListPage extends StatefulWidget {
  const GroupListPage({Key? key}) : super(key: key);

  @override
  State<GroupListPage> createState() => _GroupListPageState();
}

class _GroupListPageState extends State<GroupListPage> {
  final GroupService firestoreService = GroupService();
  final TextEditingController textController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String filter = '';
  String selectedFilter = 'All';

  List<String> filterOptions = [
    'All',
    'Created by me',
    'Joined by me',
    'Not a member'
  ];

  void openGroupBox({String? docID, String? currentGroupName}) {
    if (currentGroupName != null) {
      textController.text = currentGroupName;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(docID == null ? 'Add Group' : 'Edit Group'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Enter group name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              textController.clear();
            },
            child: const Text('Cancel'),
          ),
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
            child: Text(docID == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Groups"),
        backgroundColor: Colors.deepPurple,
      ),
      floatingActionButton: currentUser != null
          ? FloatingActionButton(
              onPressed: openGroupBox,
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        filter = value.toLowerCase();
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Search',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedFilter,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedFilter = newValue!;
                    });
                  },
                  items: filterOptions
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: firestoreService.getGroupStream(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                List<DocumentSnapshot> groupsList = snapshot.data!.docs;

                if (groupsList.isEmpty) {
                  return const Center(
                    child: Text(
                      'No groups available.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                return Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: groupsList.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot document = groupsList[index];
                      String docID = document.id;

                      Map<String, dynamic> data =
                          document.data() as Map<String, dynamic>;
                      String groupText = data['group'];
                      List<dynamic> members = data['members'] ?? [];
                      String createdBy = data['createdBy'];

                      bool isOwner = createdBy == currentUser?.uid;
                      bool isMember = members.contains(currentUser?.uid);

                      if ((filter.isEmpty ||
                              groupText.toLowerCase().contains(filter)) &&
                          (selectedFilter == 'All' ||
                              (selectedFilter == 'Created by me' && isOwner) ||
                              (selectedFilter == 'Joined by me' && isMember) ||
                              (selectedFilter == 'Not a member' &&
                                  !isMember))) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(groupText),
                            subtitle: Text('Members: ${members.length}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isOwner) ...[
                                  IconButton(
                                    onPressed: () => openGroupBox(
                                        docID: docID,
                                        currentGroupName: groupText),
                                    icon: const Icon(Icons.edit,
                                        color: Colors.deepPurple),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        firestoreService.deleteGroup(docID),
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                  ),
                                ] else ...[
                                  IconButton(
                                    onPressed: () {
                                      if (isMember) {
                                        firestoreService.leaveGroup(docID);
                                      } else {
                                        firestoreService.joinGroup(docID);
                                      }
                                    },
                                    icon: Icon(
                                        isMember
                                            ? Icons.exit_to_app
                                            : Icons.group_add,
                                        color: isMember
                                            ? Colors.red
                                            : Colors.green),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      } else {
                        return Container(); // Return an empty container if not matched with the filter
                      }
                    },
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'An error occurred: ${snapshot.error}',
                    style: const TextStyle(fontSize: 18, color: Colors.red),
                  ),
                );
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
