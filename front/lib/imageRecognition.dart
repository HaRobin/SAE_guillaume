import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'dart:math' as math;

import 'camera.dart';
import 'bndbox.dart';

class ImageRecognition extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ImageRecognition(this.cameras, {super.key});

  @override
  _ImageRecognitionState createState() => _ImageRecognitionState();
}

class _ImageRecognitionState extends State<ImageRecognition> {
  List<dynamic> _recognitions = [];
  int _imageHeight = 0;
  int _imageWidth = 0;

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  loadModel() async {
    String res;
    res = (await Tflite.loadModel(
      model: "assets/yolov2_tiny.tflite",
      labels: "assets/yolov2_tiny.txt",
    ))!;
    print(res);
  }

  setRecognitions(recognitions, imageHeight, imageWidth) {
    setState(() {
      _recognitions = recognitions;
      _imageHeight = imageHeight;
      _imageWidth = imageWidth;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Camera(
            widget.cameras,
            setRecognitions,
          ),
          BndBox(
            _recognitions,
            math.max(_imageHeight, _imageWidth),
            math.min(_imageHeight, _imageWidth),
            screen.height,
            screen.width,
          ),
        ],
      ),
    );
  }
}
