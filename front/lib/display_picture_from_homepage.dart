import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:native_exif/native_exif.dart';
import 'package:photo_manager/photo_manager.dart';

class DisplayPictureFromHome extends StatelessWidget {
  final AssetEntity image;

  const DisplayPictureFromHome({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultats'),
        actions: [
          IconButton(
              onPressed: () {
                showResults(context);
                HapticFeedback.vibrate();
              },
              icon: Icon(Icons.format_list_bulleted)),
        ],
      ),
      body: FutureBuilder(
        future: image.file,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ListTile(title: Text('Loading...'));
          }
          final file = snapshot.data!;

          return Scaffold(
            body: Image.file(file),
          );
        },
      ),
    );
  }

  Future<void> showResults(BuildContext context) async {
    String result = "";

    final file = await image.file;
    final exif = await Exif.fromPath(file!.path);

    final attributes = await exif.getAttributes();

    attributes!.forEach((k, v) => result += "$k : $v\n");

    if (!context.mounted) {
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Resultats'),
          content: Text(result),
          actions: <Widget>[
            TextButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                HapticFeedback.vibrate();
              },
            ),
          ],
        );
      },
    );
  }
}
