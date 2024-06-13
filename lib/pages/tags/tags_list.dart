import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fp_ppb_e8/services/tags_firestore.dart';

class TagListPage extends StatefulWidget {
  final Color mainBackgroundColor;
  final Color mainAppBarBackgroundColor;
  final Color mainAppBarTextColor;
  final Color mainIconColor;
  final Color dialogBackgroundColor;
  final Color dialogTextColor;
  final Color loadingIndicatorColor;
  final Color listItemBackgroundColor;

  const TagListPage({
    Key? key,
    required this.mainBackgroundColor,
    required this.mainAppBarBackgroundColor,
    required this.mainAppBarTextColor,
    required this.mainIconColor,
    required this.dialogBackgroundColor,
    required this.dialogTextColor,
    required this.loadingIndicatorColor,
    required this.listItemBackgroundColor,
  }) : super(key: key);

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
        backgroundColor: widget.dialogBackgroundColor,
        title: Text(
          docID == null ? 'Add Tag' : 'Edit Tag',
          style: TextStyle(color: widget.dialogTextColor),
        ),
        content: TextField(
          controller: textController,
          style: TextStyle(color: widget.dialogTextColor),
          decoration: InputDecoration(
            hintText: 'Enter tags separated by commas',
            hintStyle: TextStyle(color: widget.dialogTextColor),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (docID == null) {
                List<String> tags = textController.text.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
                firestoreService.addTag(tags);
              } else {
                firestoreService.updateTag(docID, textController.text);
              }

              textController.clear();
              Navigator.pop(context);
              fetchAllTags();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.mainIconColor,
            ),
            child: Text("Save", style: TextStyle(color: widget.dialogTextColor)),
          ),
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

  Widget buildTagList(List<DocumentSnapshot> tagsList) {
    return ListView.builder(
      itemCount: tagsList.length,
      itemBuilder: (context, index) {
        DocumentSnapshot document = tagsList[index];
        String docID = document.id;

        Map<String, dynamic> data = document.data() as Map<String, dynamic>;
        String tagName = data['tag_name'];
        String tagUser = data['createdByEmail'];

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            tileColor: widget.dialogBackgroundColor,
            title: Text(tagName, style: TextStyle(fontWeight: FontWeight.bold,color: widget.dialogTextColor)),
            subtitle: Text(tagUser, style: TextStyle(color: widget.dialogTextColor)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => openTagBox(docID: docID, initialTags: [tagName]),
                  icon: Icon(Icons.edit, color: widget.mainIconColor),
                ),
                IconButton(
                  onPressed: () => firestoreService.deleteTag(docID),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.mainBackgroundColor,
      appBar: AppBar(
        title: Text(pageTitle, style: TextStyle(color: widget.mainAppBarTextColor)),
        backgroundColor: widget.mainAppBarBackgroundColor,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openTagBox(),
        backgroundColor: widget.mainIconColor,
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search tags',
                  hintStyle: TextStyle(color: widget.mainAppBarBackgroundColor),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search, color: widget.mainIconColor),
                    onPressed: searchTags,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height - kToolbarHeight - 80,
              child: isSearching
                  ? buildTagList(searchResults)
                  : StreamBuilder<QuerySnapshot>(
                stream: firestoreService.getTagsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return buildTagList(snapshot.data!.docs);
                  } else {
                    return Center(
                      child: CircularProgressIndicator(
                        color: widget.loadingIndicatorColor,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
