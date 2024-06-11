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
  List<DocumentSnapshot> allTags = [];
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    fetchAllTags();
  }

  void fetchAllTags() async {
    QuerySnapshot querySnapshot = await firestoreService.getTagsStream().first;
    setState(() {
      allTags = querySnapshot.docs;
    });
  }

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
                if (docID == null) {
                  firestoreService.addTag(tags);
                } else {
                  firestoreService.updateTag(docID, tags);
                }

                textController.clear();
                Navigator.pop(context);
                fetchAllTags();
              },
              child: const Text("Save"))
        ],
      ),
    );
  }

  void searchTags() {
    String searchText = searchController.text.trim().toLowerCase();
    setState(() {
      isSearching = searchText.isNotEmpty;
      searchResults = allTags.where((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String tagName = data['tag_name'].toLowerCase();
        return tagName.contains(searchText);
      }).toList();
      pageTitle = "Tags List";
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
            child: isSearching
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
                        onPressed: () => firestoreService.deleteTag(docID),
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
                              onPressed: () => firestoreService.deleteTag(docID),
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
