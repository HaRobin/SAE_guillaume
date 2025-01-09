import 'package:flutter/material.dart';
import 'package:front/models/screen_params.dart';
import 'package:front/ui/detector_widget.dart';

/// [HomeView] stacks [DetectorWidget]
class CameraViewWidget extends StatelessWidget {
  const CameraViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenParams.screenSize = MediaQuery.sizeOf(context);
    return Scaffold(
      key: GlobalKey(),
      backgroundColor: Colors.black,
      body: DetectorWidget(),
    );
  }
}
