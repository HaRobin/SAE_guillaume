import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front/models/yolo.dart';
import 'package:image/image.dart' as img;

class ObjectDetection {
  static const String _modelPath = 'assets/models/yolov8_cards.tflite';
  static const String _labelPath = 'assets/models/labelcard.txt';

  YoloModel? model;
  List<String>? _labels;

  ObjectDetection() {
    _loadModel();
    _loadLabels();
  }

  Future<void> _loadModel() async {
    model = YoloModel(_modelPath, 640, 640, 52);
    await model!.init();
  }

  Future<void> _loadLabels() async {
    final labelsRaw = await rootBundle.loadString(_labelPath);
    _labels = labelsRaw.split('\n');
  }

  Future<Uint8List> analyseImage(String imagePath) async {
    final imageData = File(imagePath).readAsBytesSync();

    final image = img.decodeImage(imageData);

    final (newClasses, newBboxes, newScores) =
        await model!.inferAndPostprocess(image!);

    // Location
    final locationsRaw = newBboxes;
    final locations = locationsRaw.map((list) {
      return list.map((value) => value.toInt()).toList();
    }).toList();

    // Classes
    final classes = newClasses.map((value) => value.toInt()).toList();

    final List<String> classication = [];
    for (var i = 0; i < newBboxes.length; i++) {
      classication.add(_labels![classes[i]]);
    }

    //box
    for (var i = 0; i < newBboxes.length; i++) {
      final x1 = locations[i][0] - locations[i][2] ~/ 2;
      final y1 = locations[i][1] - locations[i][3] ~/ 2;
      final x2 = locations[i][0] + locations[i][2] ~/ 2;
      final y2 = locations[i][1] + locations[i][3] ~/ 2;

      debugPrint('-RAHAAAAAAAAA---------------------');
      debugPrint(locations[i].toString());
      debugPrint(x1.toString());
      debugPrint(y1.toString());
      debugPrint(x2.toString());
      debugPrint(y2.toString());

      //Dessins
      img.drawRect(
        image,
        x1: x1,
        y1: y1,
        x2: x2,
        y2: y2,
        color: img.ColorRgb8(255, 0, 0),
        thickness: 10,
      );

      final labelText = '${classication[i]} ${newScores[i].toStringAsFixed(2)}';

      final labelX = x1 + 5;
      final labelY = y1 + 20;

      img.drawString(
        image,
        labelText,
        font: img.arial48,
        x: labelX,
        y: labelY,
        color: img.ColorRgb8(50, 50, 50),
      );
    }

    return img.encodeJpg(image);
  }
}
