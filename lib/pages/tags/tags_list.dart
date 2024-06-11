import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fp_ppb_e8/services/tags_firestore.dart';
import 'package:fp_ppb_e8/components/tags/card.dart';

class TagListPage extends StatefulWidget {
  const TagListPage({Key? key}) : super(key: key);

  @override
  State<TagListPage> createState() => _TagListPageState();
}

class _TagListPageState extends State<TagListPage> {
  final TagService firestoreService = TagService();
  final TextEditingController textController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  String pageTitle = "Tags List";

  List<DocumentSnapshot> searchResults = [];

  void openTagBox({String? docID, List<String>? initialTags}) {
    if (initialTags != null) {
      textController.text = initialTags.join(',');
    } else {
      textController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: 'Enter tags separated by commas'),
        ),
        actions: [
          ElevatedButton(
              onPressed: () {
                List<String> tags = textController.text.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
                // String newTags = textController.text;
                if (docID == null) {
                  firestoreService.addTag(tags); // Replace 'dummyNoteID' with actual note ID
                } else {
                  firestoreService.updateTag(docID, tags);
                }

                textController.clear();
                Navigator.pop(context);
              },
              child: const Text("Save"))
        ],
      ),
    );
  }

  void searchTags() async {
    List<String> searchedTags = searchController.text.split(',').map((tag) => tag.trim()).toList();
    QuerySnapshot querySnapshot = await firestoreService.getByTags(searchedTags);

    setState(() {
      searchResults = querySnapshot.docs;
      pageTitle = searchController.text.isNotEmpty ? "Searching: ${searchController.text}" : "Tags List";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
        backgroundColor: Colors.lightBlue,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openTagBox(),
        backgroundColor: Colors.lightBlue,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search tags',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: searchTags,
                ),
              ),
            ),
          ),
          Expanded(
            child: searchResults.isNotEmpty
                ? ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                DocumentSnapshot document = searchResults[index];
                String docID = document.id;

                Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                String tagName = data['tag_name'];
                String tagUser = data['createdBy'];

                return ListTile(
                  title: Text(tagName),
                  subtitle: Text(tagUser),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => openTagBox(docID: docID, initialTags: [tagName]),
                        icon: const Icon(Icons.settings),
                      ),
                      IconButton(
                        onPressed: () => firestoreService.deleteTag(docID), // Replace 'dummyNoteID' with actual note ID
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  ),
                );
              },
            )
                : StreamBuilder<QuerySnapshot>(
              stream: firestoreService.getTagsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<DocumentSnapshot> tagsList = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: tagsList.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot document = tagsList[index];
                      String docID = document.id;

                      Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                      String tagName = data['tag_name'];
                      String tagUser = data['createdBy'];

                      return ListTile(
                        title: Text(tagName),
                        subtitle: Text(tagUser),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => openTagBox(docID: docID, initialTags: [tagName]),
                              icon: const Icon(Icons.settings),
                            ),
                            IconButton(
                              onPressed: () => firestoreService.deleteTag(docID), // Replace 'dummyNoteID' with actual note ID
                              icon: const Icon(Icons.delete),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
