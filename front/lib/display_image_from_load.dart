import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:gal/gal.dart';
import 'package:native_exif/native_exif.dart';
import 'package:path_provider/path_provider.dart';

class DisplayImageFromLoad extends StatelessWidget {
  final Future<Uint8List>
      imageFuture; // Accept the Future<Uint8List> as a parameter

  const DisplayImageFromLoad({super.key, required this.imageFuture});

  // Method to save the image and handle EXIF and album operations
  Future<void> _saveAndProcessImage(
      Uint8List image, BuildContext context) async {
    // Get the directory to save the image
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/picked_image.jpg';

    // Save the Uint8List as a file
    final file = File(filePath);
    await file.writeAsBytes(image);

    // Now you can use the file for EXIF operations
    final exif = await Exif.fromPath(filePath);
    // Assuming results are available (you'll need to define them)

    await exif.close();

    // Save to album "GuillaumeAI"
    await Gal.putImage(filePath, album: "GuillaumeAI");
    showToast("Image enregistrée");
    Navigator.pop(context, 'image analyzed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Image :D"),
        actions: [
          IconButton(
            onPressed: () async {
              // Get the image data from the Future and save it
              final image = await imageFuture;
              await _saveAndProcessImage(image, context);
            },
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<Uint8List>(
          future:
              imageFuture, // Use the Future<Uint8List> passed into the widget
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Show a loader while waiting for the operation to complete
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              // Handle error if any occurs during the Future operation
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              // After the image is processed, show the image
              return Column(
                children: <Widget>[
                  Expanded(
                    child: Center(child: Image.memory(snapshot.data!)),
                  ),
                ],
              );
            } else {
              // Handle case where no data is available
              return const Center(child: Text("No image data found."));
            }
          },
        ),
      ),
    );
  }
}
