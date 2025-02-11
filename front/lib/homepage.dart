// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front/desciption.dart';
import 'package:front/display_image_from_load.dart';
import 'package:front/display_picture_from_homepage.dart';
import 'package:front/service/detector_service_from_load.dart';
import 'package:front/ui/camera_view_widget.dart';
import 'package:front/models/screen_params.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key, required this.title, required this.cameras});
  final String title;
  final List<CameraDescription> cameras;

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<AssetEntity> photos = [];
  final ObjectDetection _objectDetection = ObjectDetection();

  @override
  void initState() {
    super.initState();
    fetchPhotos(); // Trigger the fetch when the widget is first created.
  }

  /// Fetches photos from the "GuillaumeAI" album.
  Future<void> fetchPhotos() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (permission.isAuth) {
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList();

      AssetPathEntity? path =
          paths.where((path) => path.name == "GuillaumeAI").first;

      final assetList = await path.getAssetListPaged(page: 0, size: 100);

      setState(() {
        photos = assetList;
      });
    } else {
      debugPrint('No perm');
      return;
    }
  }

  Future<void> processNewImage() async {
    debugPrint('processNewImage called');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    final picker = ImagePicker();
    final XFile? newImage = await picker.pickImage(source: ImageSource.gallery);

    Navigator.of(context).pop();

    if (newImage != null) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DisplayImageFromLoad(
            imageFuture: _objectDetection.analyseImage(newImage.path),
          ),
        ),
      );

      if (result != null && result == 'image analyzed') {
        setState(() {
          fetchPhotos(); // Re-fetch the photos after image analysis
        });
      }
    } else {
      debugPrint("No image selected.");
    }
    HapticFeedback.vibrate();
  }

  @override
  Widget build(BuildContext context) {
    ScreenParams.screenSize = MediaQuery.sizeOf(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: photos.isEmpty
          ? const Center(child: Text("Pas de photos enregistrées"))
          : ListView.builder(
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                return FutureBuilder<File?>(
                  future: photo.file,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const ListTile(title: Text('Loading...'));
                    }
                    final file = snapshot.data!;
                    return ListTile(
                      leading: Image.file(
                        file,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                      title: Text("Photo ${index + 1}"),
                      subtitle: Text(
                        'Date: ${photo.createDateTime}',
                      ),
                      onTap: () async {
                        // Navigate to display the selected photo
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                DisplayPictureFromHome(image: photo),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: Row(
        children: [
          SizedBox(
            width: (ScreenParams.screenSize.width / 3),
            child: ElevatedButton(
              onPressed: processNewImage,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Icon(
                  Icons.add_photo_alternate,
                  color: Colors.white,
                  size: 35.0,
                ),
              ),
            ),
          ),
          SizedBox(
            width: (ScreenParams.screenSize.width / 3),
            child: ElevatedButton(
              onPressed: () => {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return CameraViewWidget();
                })),
                HapticFeedback.vibrate()
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Icon(
                  Icons.photo_camera,
                  color: Colors.white,
                  size: 35.0,
                ),
              ),
            ),
          ),
          SizedBox(
            width: (ScreenParams.screenSize.width / 3),
            child: ElevatedButton(
              onPressed: () => {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return DescriptionPage();
                }))
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Icon(
                  Icons.description,
                  color: Colors.white,
                  size: 35.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
