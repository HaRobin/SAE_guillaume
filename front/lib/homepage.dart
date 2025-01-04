import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:front/ui/camera_view_widget.dart';
import 'package:front/ui/search_bar_widget.dart';
import 'package:front/models/screen_params.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key, required this.title, required this.cameras});
  final String title;
  final List<CameraDescription> cameras;
  @override
  Widget build(BuildContext context) {
    ScreenParams.screenSize = MediaQuery.sizeOf(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          SearchBarWidget()
        ],
      ),
      body: Center(child: Text("Historique : il faut le back pour ça")),
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
              onPressed: () {},
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
