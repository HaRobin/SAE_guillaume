// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oktoast/oktoast.dart';
import 'package:gal/gal.dart';
import 'package:native_exif/native_exif.dart';
import 'package:path_provider/path_provider.dart';

class DisplayImageFromLoad extends StatelessWidget {
  final Future<Uint8List> imageFuture;

  const DisplayImageFromLoad({super.key, required this.imageFuture});

  Future<void> _saveAndProcessImage(
      Uint8List image, BuildContext context) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/picked_image.jpg';

    final file = File(filePath);
    await file.writeAsBytes(image);

    final exif = await Exif.fromPath(filePath);

    await exif.close();

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
              final image = await imageFuture;
              await _saveAndProcessImage(image, context);
              HapticFeedback.heavyImpact();
            },
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<Uint8List>(
          future: imageFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
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
