import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image_lib;
import 'package:front/models/recognition.dart';
import 'package:front/utils/image_utils.dart';
import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:front/models/nms.dart';

enum _Codes {
  init,
  busy,
  ready,
  detect,
  result,
}

/// A command sent between [Detector] and [_DetectorServer].
class _Command {
  const _Command(this.code, {this.args});

  final _Codes code;
  final List<Object>? args;
}

/// A Simple Detector that handles object detection via Service
///
/// All the heavy operations like pre-processing, detection, ets,
/// are executed in a background isolate.
/// This class just sends and receives messages to the isolate.
class Detector {
  static const String _modelPath = 'assets/models/yolov8_cards.tflite';
  static const String _labelPath = 'assets/models/labelcard.txt';

  Detector._(this._isolate, this._interpreter, this._labels);

  final Isolate _isolate;
  late final Interpreter _interpreter;
  late final List<String> _labels;

  // To be used by detector (from UI) to send message to our Service ReceivePort
  late final SendPort _sendPort;

  bool _isReady = false;

  // // Similarly, StreamControllers are stored in a queue so they can be handled
  // // asynchronously and serially.
  final StreamController<Map<String, dynamic>> resultsStream =
      StreamController<Map<String, dynamic>>();

  /// Open the database at [path] and launch the server on a background isolate..
  static Future<Detector> start() async {
    final ReceivePort receivePort = ReceivePort();
    // sendPort - To be used by service Isolate to send message to our ReceiverPort
    final Isolate isolate =
        await Isolate.spawn(_DetectorServer._run, receivePort.sendPort);

    final Detector result = Detector._(
      isolate,
      await _loadModel(),
      await _loadLabels(),
    );
    receivePort.listen((message) {
      result._handleCommand(message as _Command);
    });
    return result;
  }

  static Future<Interpreter> _loadModel() async {
    final interpreterOptions = InterpreterOptions();

    // Use XNNPACK Delegate
    if (Platform.isAndroid) {
      interpreterOptions.addDelegate(XNNPackDelegate());
      interpreterOptions.addDelegate(GpuDelegateV2());
    }

    return Interpreter.fromAsset(
      _modelPath,
      options: interpreterOptions..threads = 4,
    );
  }

  static Future<List<String>> _loadLabels() async {
    return (await rootBundle.loadString(_labelPath)).split('\n');
  }

  /// Starts CameraImage processing
  void processFrame(CameraImage cameraImage) {
    if (_isReady) {
      _sendPort.send(_Command(_Codes.detect, args: [cameraImage]));
    }
  }

  /// Handler invoked when a message is received from the port communicating
  /// with the database server.
  void _handleCommand(_Command command) {
    switch (command.code) {
      case _Codes.init:
        _sendPort = command.args?[0] as SendPort;
        RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
        _sendPort.send(_Command(_Codes.init, args: [
          rootIsolateToken,
          _interpreter.address,
          _labels,
        ]));
      case _Codes.ready:
        _isReady = true;
      case _Codes.busy:
        _isReady = false;
      case _Codes.result:
        _isReady = true;
        resultsStream.add(command.args?[0] as Map<String, dynamic>);
      default:
        debugPrint('Detector unrecognized command: ${command.code}');
    }
  }

  void stop() {
    _isolate.kill();
  }
}

/// The portion of the [Detector] that runs on the background isolate.
///
/// This is where we use the new feature Background Isolate Channels, which
/// allows us to use plugins from background isolates.
class _DetectorServer {
  Interpreter? _interpreter;
  List<String>? _labels;

  _DetectorServer(this._sendPort);

  final SendPort _sendPort;

  // ----------------------------------------------------------------------
  // Here the plugin is used from the background isolate.
  // ----------------------------------------------------------------------

  /// The main entrypoint for the background isolate sent to [Isolate.spawn].
  static void _run(SendPort sendPort) {
    ReceivePort receivePort = ReceivePort();
    final _DetectorServer server = _DetectorServer(sendPort);
    receivePort.listen((message) async {
      final _Command command = message as _Command;
      await server._handleCommand(command);
    });
    // receivePort.sendPort - used by UI isolate to send commands to the service receiverPort
    sendPort.send(_Command(_Codes.init, args: [receivePort.sendPort]));
  }

  /// Handle the [command] received from the [ReceivePort].
  Future<void> _handleCommand(_Command command) async {
    switch (command.code) {
      case _Codes.init:
        // ----------------------------------------------------------------------
        // The [RootIsolateToken] is required for
        // [BackgroundIsolateBinaryMessenger.ensureInitialized] and must be
        // obtained on the root isolate and passed into the background isolate via
        // a [SendPort].
        // ----------------------------------------------------------------------
        RootIsolateToken rootIsolateToken =
            command.args?[0] as RootIsolateToken;
        // ----------------------------------------------------------------------
        // [BackgroundIsolateBinaryMessenger.ensureInitialized] for each
        // background isolate that will use plugins. This sets up the
        // [BinaryMessenger] that the Platform Channels will communicate with on
        // the background isolate.
        // ----------------------------------------------------------------------
        BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
        _interpreter = Interpreter.fromAddress(command.args?[1] as int);
        _labels = command.args?[2] as List<String>;
        _sendPort.send(const _Command(_Codes.ready));
      case _Codes.detect:
        _sendPort.send(const _Command(_Codes.busy));
        _convertCameraImage(command.args?[0] as CameraImage);
      default:
        debugPrint('_DetectorService unrecognized command ${command.code}');
    }
  }

  void _convertCameraImage(CameraImage cameraImage) {
    var preConversionTime = DateTime.now().millisecondsSinceEpoch;

    convertCameraImageToImage(cameraImage).then((image) {
      if (image != null) {
        if (Platform.isAndroid) {
          image = image_lib.copyRotate(image, angle: 90);
        }
        debugPrint('Convert IMAAAAAGE -------');
        debugPrint('Width');
        debugPrint(image.width.toString());
        debugPrint('Height');
        debugPrint(image.height.toString());

        debugPrint('Screen size');
        debugPrint('Screen size');

        final results = analyseImage(image, preConversionTime);
        _sendPort.send(_Command(_Codes.result, args: [results]));
      }
    });
  }

  Map<String, dynamic> analyseImage(
      image_lib.Image? image, int preConversionTime) {
    var conversionElapsedTime =
        DateTime.now().millisecondsSinceEpoch - preConversionTime;

    var preProcessStart = DateTime.now().millisecondsSinceEpoch;

    var preProcessElapsedTime =
        DateTime.now().millisecondsSinceEpoch - preProcessStart;

    var inferenceTimeStart = DateTime.now().millisecondsSinceEpoch;

    final (newClasses, newBboxes, newScores) = inferAndPostprocess(image!);

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

    /// Generate recognitions
    List<Recognition> recognitions = [];
    for (var i = 0; i < newBboxes.length; i++) {
      debugPrint('-----------------------------------');
      debugPrint(locations[i].toString());
      final x1 = locations[i][0].toDouble();
      final y1 = locations[i][1].toDouble();
      final x2 = locations[i][2].toDouble();
      final y2 = locations[i][3].toDouble();
      Rect location = Rect.fromLTWH(x1, y1, x2, y2);
      debugPrint(location.toString());
      debugPrint('-----------------------------------');
      recognitions.add(Recognition(i, classication[i], newScores[i], location));
    }

    var inferenceElapsedTime =
        DateTime.now().millisecondsSinceEpoch - inferenceTimeStart;

    var totalElapsedTime =
        DateTime.now().millisecondsSinceEpoch - preConversionTime;

    return {
      "recognitions": recognitions,
      "stats": <String, String>{
        'Conversion time:': conversionElapsedTime.toString(),
        'Pre-processing time:': preProcessElapsedTime.toString(),
        'Inference time:': inferenceElapsedTime.toString(),
        'Total prediction time:': totalElapsedTime.toString(),
        'Frame': '${image.width} X ${image.height}',
      },
    };
  }

  /// Object detection main function
  List<List<double>> _infer(Image image) {
    assert(_interpreter != null, 'The model must be initialized');

    final imgResized = copyResize(image, width: 640, height: 640);
    final imgNormalized = List.generate(
      640,
      (y) => List.generate(
        640,
        (x) {
          final pixel = imgResized.getPixel(x, y);
          return [pixel.rNormalized, pixel.gNormalized, pixel.bNormalized];
        },
      ),
    );

    final output = [
      List<List<double>>.filled(4 + 52, List<double>.filled(8400, 0))
    ];
    int predictionTimeStart = DateTime.now().millisecondsSinceEpoch;
    _interpreter!.run([imgNormalized], output);
    debugPrint(
        'Prediction time: ${DateTime.now().millisecondsSinceEpoch - predictionTimeStart} ms');
    return output[0];
  }

  (List<int>, List<List<double>>, List<double>) postprocess(
    List<List<double>> unfilteredBboxes,
    int imageWidth,
    int imageHeight, {
    double confidenceThreshold = 0.3,
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

    debugPrint(bboxes.toString());
    for (var bbox in bboxes) {
      bbox[0] *= imageWidth;
      bbox[1] *= imageHeight;
      bbox[2] *= imageWidth;
      bbox[3] *= imageHeight;
    }
    return (classes, bboxes, scores);
  }

  (List<int>, List<List<double>>, List<double>) inferAndPostprocess(
    Image image, {
    double confidenceThreshold = 0.3,
    double iouThreshold = 0.4,
    bool agnostic = false,
  }) =>
      postprocess(
        _infer(image),
        image.width,
        image.height,
        confidenceThreshold: confidenceThreshold,
        iouThreshold: iouThreshold,
        agnostic: agnostic,
      );
}
