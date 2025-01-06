import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:front/display_picture_screen.dart';
import 'package:front/models/recognition.dart';
import 'package:front/models/screen_params.dart';
import 'package:front/service/detector_service.dart';
import 'package:front/ui/box_widget.dart';
import 'package:front/ui/detected_widget.dart';

/// [DetectorWidget] sends each frame for inference
class DetectorWidget extends StatefulWidget {
  /// Constructor
  const DetectorWidget({super.key});

  @override
  State<DetectorWidget> createState() => _DetectorWidgetState();
}

class _DetectorWidgetState extends State<DetectorWidget>
    with WidgetsBindingObserver {
  /// List of available cameras
  late List<CameraDescription> cameras;

  /// Controller
  CameraController? _cameraController;

  // use only when initialized, so - not null
  get _controller => _cameraController;

  /// Object Detector is running on a background [Isolate]. This is nullable
  /// because acquiring a [Detector] is an asynchronous operation. This
  /// value is `null` until the detector is initialized.
  Detector? _detector;
  StreamSubscription? _subscription;

  /// Results to draw bounding boxes
  List<Recognition>? results;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initStateAsync();
  }

  void _initStateAsync() async {
    // initialize preview and CameraImage stream
    _initializeCamera();
    // Spawn a new isolate
    Detector.start().then((instance) {
      setState(() {
        _detector = instance;
        _subscription = instance.resultsStream.stream.listen((values) {
          setState(() {
            results = values['recognitions'];
          });
        });
      });
    });
  }

  /// Initializes the camera by setting [_cameraController]
  void _initializeCamera() async {
    cameras = await availableCameras();
    // cameras[0] for back-camera
    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.veryHigh,
      enableAudio: false,
    )..initialize().then((_) async {
        await _controller.startImageStream(onLatestImageAvailable);
        setState(() {});

        /// previewSize is size of each image frame captured by controller
        ///
        /// 352x288 on iOS, 240p (320x240) on Android with ResolutionPreset.low
        ScreenParams.previewSize = _controller.value.previewSize!;
      });
  }

  @override
  Widget build(BuildContext context) {
    // Return empty container while the camera is not initialized
    if (_cameraController == null || !_controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      body: Column(
        children: [
          //_detectedWidget(),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: CameraPreview(_controller),
                  ),
                ),
                _boundingBoxes(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Capture the image
            final image = await _controller.takePicture();

            if (!context.mounted) return;

            // Load the captured image into a `ui.Image`
            final capturedImage =
                await decodeImageFromList(await image.readAsBytes());

            // Create a picture recorder and canvas
            final recorder = PictureRecorder();
            final canvas = Canvas(recorder);

            // Draw the captured image
            final paint = Paint();
            canvas.drawImage(capturedImage, Offset.zero, paint);

            final double scaleX = capturedImage.width / 300;
            final double scaleY = capturedImage.height / 300;

            List<Recognition> theResults = [];

            // Draw bounding boxes
            if (results != null) {
              theResults = results!;
              for (var result in theResults) {
                Color color = Colors.primaries[(result.label.length +
                        result.label.codeUnitAt(0) +
                        result.id) %
                    Colors.primaries.length];

                final rect = Rect.fromLTWH(
                  result.location.left * scaleX,
                  result.location.top * scaleY,
                  result.location.width * scaleX,
                  result.location.height * scaleY,
                );
                final boxPaint = Paint()
                  ..color = color
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 6.0;
                canvas.drawRect(rect, boxPaint);

                final textPainter = TextPainter(
                  text: TextSpan(
                    text: '${result.label} ${result.score.toStringAsFixed(2)}',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        backgroundColor: color),
                  ),
                  textDirection: TextDirection.ltr,
                );
                textPainter.layout();
                textPainter.paint(
                    canvas,
                    Offset(result.location.left * scaleX,
                        result.location.top * scaleY + 5));
              }
            }

            // Convert the canvas to an image
            final picture = recorder.endRecording();
            final img = await picture.toImage(
              capturedImage.width,
              capturedImage.height,
            );

            // Convert the image to bytes and save it
            final byteData = await img.toByteData(format: ImageByteFormat.png);
            final buffer = byteData!.buffer.asUint8List();

            // Save the image to a file
            final newFilePath = '${image.path}_with_boxes.png';
            final newFile = await File(newFilePath).writeAsBytes(buffer);

            // Navigate to display the new image with bounding boxes
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    DisplayPictureScreen(imagePath: newFile.path,results: theResults,),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  Widget _detectedWidget() => (results != null)
      ? Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            color: Colors.white.withAlpha(150),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: results!
                    .map((e) => DetectedWidget(
                        e.id.toString(), e.label, e.score.toString()))
                    .toList(),
              ),
            ),
          ),
        )
      : const SizedBox.shrink();

  /// Returns Stack of bounding boxes
  Widget _boundingBoxes() {
    if (results == null) {
      return const SizedBox.shrink();
    }
    return Stack(
        children: results!.map((box) => BoxWidget(result: box)).toList());
  }

  /// Callback to receive each frame [CameraImage] perform inference on it
  void onLatestImageAvailable(CameraImage cameraImage) async {
    _detector?.processFrame(cameraImage);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
        _cameraController?.stopImageStream();
        _detector?.stop();
        _subscription?.cancel();
        break;
      case AppLifecycleState.resumed:
        _initStateAsync();
        break;
      default:
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _detector?.stop();
    _subscription?.cancel();
    super.dispose();
  }
}
