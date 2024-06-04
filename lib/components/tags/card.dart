import 'package:flutter/material.dart';

Color stringToColor(String text) {
  final int hash = text.hashCode;
  final int r = (hash & 0xFF0000) >> 16;
  final int g = (hash & 0x00FF00) >> 8;
  final int b = hash & 0x0000FF;
  return Color.fromRGBO(r, g, b, 1.0);
}

class TagData extends StatelessWidget {
  final String tagText;

  const TagData(this.tagText, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(tagText),
      avatar: CircleAvatar(
        backgroundColor: stringToColor(tagText),
        child: Text(tagText.substring(0, 2)),
      ),
      deleteIcon: const Icon(Icons.cancel),
      onDeleted: () {
        // Handle chip deletion
        print('Chip deleted');
      },
    );
  }
}
