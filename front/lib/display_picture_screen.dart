// A widget that displays the picture taken by the user.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:front/models/recognition.dart';
import 'package:gal/gal.dart';
import 'package:native_exif/native_exif.dart';
import 'package:oktoast/oktoast.dart';

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  final List<Recognition> results;

  const DisplayPictureScreen({super.key, required this.imagePath, required this.results});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultats'),
        actions: [
          IconButton(onPressed: () {showResults(context);}, icon: Icon(Icons.format_list_bulleted)),
          IconButton(onPressed: () async { 
            if(! await Gal.hasAccess()){
              await Gal.requestAccess();
            }

            final exif = await Exif.fromPath(imagePath);
            for(var element in results){
              await exif.writeAttribute(element.label, "${element.score}");
            }

            await exif.close();

            

            Gal.putImage(imagePath,album: "GuillaumeAI");
            showToast("Image enregistrée");
            
           }, icon: Icon(Icons.download),)
        ],
        
        ),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Image.file(File(imagePath)),
    );
  }

  void showResults(BuildContext context){
    String result = "";

    for (var element in results) {
      result += "- ${element.label} : ${element.score}\n" ;
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
              },
            ),
          ],
        );
      },
    );
  }
}
