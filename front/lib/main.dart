import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:front/homepage.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';

late List<CameraDescription> cameras;

Future<Null> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: $e.code\nError Message: $e.message');
  }
  PhotoManager.clearFileCache();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp(
        title: 'tflite real-time detection',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.pink[900], // Dark pink background
          primaryColor: Colors.pink, // Primary theme color
          hintColor: Colors.pinkAccent, // Accent color for hints & highlights
          colorScheme: ColorScheme.dark(
            primary: Colors.pink, // Main color for app
            secondary: Colors.pinkAccent, // Secondary color (FAB, highlights)
            surface: Colors.pink[800]!, // Card & dialog backgrounds
            onPrimary: Colors.white, // Text color on primary color
            onSecondary: Colors.black, // Text on secondary color
            onSurface: Colors.white, // Text on cards & dialogs
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.pink[700], // AppBar background
            foregroundColor: Colors.white, // AppBar text & icons
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink, // Button color
              foregroundColor: Colors.white, // Text color on button
            ),
          ),
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: Colors.white), // Large text
            bodyMedium: TextStyle(color: Colors.white), // Normal text
            bodySmall: TextStyle(color: Colors.white70), // Small text
          ),
        ),
        home: Homepage(title: "Guillaume", cameras: cameras),
      ),
    );
  }
}
