import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fp_ppb_e8/services/tags_firestore.dart';

class TagListPage extends StatefulWidget {
  const TagListPage({super.key});

  @override
  State<TagListPage> createState() => _TagListPageState();
}

class _TagListPageState extends State<TagListPage> {
  final TagService firestoreService = TagService();
  final TextEditingController textController = TextEditingController();

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
                List<String> tags = textController.text.split(',').map((tag) => tag.trim()).toList();

                if (docID == null) {
                  firestoreService.addTag(tags);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tags"),
        backgroundColor: Colors.lightBlue,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openTagBox(),
        backgroundColor: Colors.lightBlue,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
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
                  List<dynamic> tagList = data['tag_list'];
                  String tagText = tagList.join(', ');

                  return ListTile(
                    title: Text(tagText),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => openTagBox(docID: docID, initialTags: List<String>.from(tagList)),
                          icon: const Icon(Icons.settings),
                        ),
                        IconButton(
                          onPressed: () => firestoreService.deleteTag(docID),
                          icon: const Icon(Icons.delete),
                        ),
                      ],
                    ),
                  );
                });
          } else {
            return const Center(child: Text("No tags available"));
          }
        },
      ),
    );
  }
}
