import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:front/imageRecognition.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key, required this.title, required this.cameras});
  final String title;
  final List<CameraDescription> cameras;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => {
             Navigator.push(context, MaterialPageRoute(builder: (context) {
              return new ImageRecognition(cameras);
            }))
          }
          , child: const Text("Test camera"))
      ),
    );
  }
}