import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ImportPictureWidget extends StatefulWidget {
  @override
  _ImportPictureWidgetState createState() => _ImportPictureWidgetState();
}

class _ImportPictureWidgetState extends State<ImportPictureWidget> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<void> _saveImage() async {
    // Placeholder function for saving the image
    // Implement your save logic here
    print("Save Image button pressed");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Import Picture"),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _selectedImage != null
                  ? Image.file(
                      _selectedImage!,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    )
                  : Text(
                      "No image selected.",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text("Pick Image"),
                ),
                ElevatedButton(
                  onPressed: _saveImage,
                  child: Text("Save Image"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
