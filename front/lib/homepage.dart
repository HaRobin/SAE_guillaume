import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:front/display_picture_from_homepage.dart';
import 'package:front/ui/camera_view_widget.dart';
import 'package:front/ui/search_bar_widget.dart';
import 'package:front/models/screen_params.dart';
import 'package:photo_manager/photo_manager.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key, required this.title, required this.cameras});
  final String title;
  final List<CameraDescription> cameras;

  @override
  // ignore: library_private_types_in_public_api
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<AssetEntity> photos = [];

  @override
  void initState() {
    super.initState();
    fetchPhotos();
  }

  //ça marche je vais hurler
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
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenParams.screenSize = MediaQuery.sizeOf(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [SearchBarWidget()],
      ),
      body: photos.isEmpty
          ? Center(child: Text("Pas de photos enregistrées"))
          : ListView.builder(
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                return FutureBuilder<File?>(
                  future: photo.file,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return ListTile(title: Text('Loading...'));
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
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  DisplayPictureFromHome(image: photo)),
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
            width: (ScreenParams.screenSize.width / 2),
            child: ElevatedButton(
              style: ButtonStyle(
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0.0),
                          side: BorderSide()))),
              onPressed: () {
                fetchPhotos();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: const Icon(
                  Icons.photo_library,
                  color: Colors.white,
                  size: 35.0,
                ),
              ),
            ),
          ),
          SizedBox(
            width: (ScreenParams.screenSize.width / 2),
            child: ElevatedButton(
                style: ButtonStyle(
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0.0),
                            side: BorderSide()))),
                onPressed: () => {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return CameraViewWidget();
                      }))
                    },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: const Icon(
                    Icons.photo_camera,
                    color: Colors.white,
                    size: 35.0,
                  ),
                )),
          ),
        ],
      ),
    );
  }
}
