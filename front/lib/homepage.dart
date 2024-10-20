import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:front/ui/camera_view_widget.dart';
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
      ),
      body: Center(
          child: ElevatedButton(
              onPressed: () => {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return CameraViewWidget();
                    }))
                  },
              child: const Text("Test camera"))),
    );
  }
}
