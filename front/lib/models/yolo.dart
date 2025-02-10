import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart';
import 'package:front/models/nms.dart';

class YoloModel {
  final String modelPath;
  final int inWidth;
  final int inHeight;
  final int numClasses;
  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;

  YoloModel(
    this.modelPath,
    this.inWidth,
    this.inHeight,
    this.numClasses,
  );

  get address {
    return _isolateInterpreter!.address;
  }

  Future<void> init() async {
    final interpreterOptions = InterpreterOptions();
    _interpreter = await Interpreter.fromAsset(
      modelPath,
      options: interpreterOptions..threads = 4,
    );
    _isolateInterpreter =
        await IsolateInterpreter.create(address: _interpreter!.address);
  }

  Future<List<List<double>>> infer(Image image) async {
    assert(_isolateInterpreter != null, 'The model must be initialized');

    final imgResized = copyResize(image, width: inWidth, height: inHeight);
    final imgNormalized = List.generate(
      inHeight,
      (y) => List.generate(
        inWidth,
        (x) {
          final pixel = imgResized.getPixel(x, y);
          return [pixel.rNormalized, pixel.gNormalized, pixel.bNormalized];
        },
      ),
    );

    final output = [
      List<List<double>>.filled(4 + numClasses, List<double>.filled(8400, 0))
    ];
    int predictionTimeStart = DateTime.now().millisecondsSinceEpoch;
    await _isolateInterpreter!.run([imgNormalized], output);
    debugPrint(
        'Prediction time: ${DateTime.now().millisecondsSinceEpoch - predictionTimeStart} ms');
    return output[0];
  }

  (List<int>, List<List<double>>, List<double>) postprocess(
    List<List<double>> unfilteredBboxes,
    int imageWidth,
    int imageHeight, {
    double confidenceThreshold = 0.5,
    double iouThreshold = 0.1,
    bool agnostic = false,
  }) {
    List<int> classes;
    List<List<double>> bboxes;
    List<double> scores;
    int nmsTimeStart = DateTime.now().millisecondsSinceEpoch;
    (classes, bboxes, scores) = nms(
      unfilteredBboxes,
      confidenceThreshold: confidenceThreshold,
      iouThreshold: iouThreshold,
      agnostic: agnostic,
    );
    debugPrint(
        'NMS time: ${DateTime.now().millisecondsSinceEpoch - nmsTimeStart} ms');
    for (var bbox in bboxes) {
      bbox[0] *= imageWidth;
      bbox[1] *= imageHeight;
      bbox[2] *= imageWidth;
      bbox[3] *= imageHeight;
    }
    return (classes, bboxes, scores);
  }

  Future<(List<int>, List<List<double>>, List<double>)> inferAndPostprocess(
    Image image, {
    double confidenceThreshold = 0.5,
    double iouThreshold = 0.1,
    bool agnostic = false,
  }) async =>
      postprocess(
        await infer(image),
        image.width,
        image.height,
        confidenceThreshold: confidenceThreshold,
        iouThreshold: iouThreshold,
        agnostic: agnostic,
      );
}
