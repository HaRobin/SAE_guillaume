// A widget that displays the picture taken by the user.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front/models/recognition.dart';
import 'package:gal/gal.dart';
//import 'package:native_exif/native_exif.dart';
import 'package:oktoast/oktoast.dart';
import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  final List<Recognition> results;

  const DisplayPictureScreen(
      {super.key, required this.imagePath, required this.results});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultats'),
        actions: [
          IconButton(
              onPressed: () {
                showResults(context);
                HapticFeedback.vibrate();
              },
              icon: Icon(Icons.format_list_bulleted)),
          IconButton(
            onPressed: () async {
              if (!await Gal.hasAccess()) {
                await Gal.requestAccess();
              }

              String deviceId = "unknown";
              String? maybeDeviceId = await _getDeviceId();
              if (maybeDeviceId != null) {
                // ignore: unnecessary_cast
                deviceId = maybeDeviceId as String;
              }

              final url = Uri.parse('http://141.94.115.100/items/images');
              final recognitionUrl =
                  Uri.parse('http://141.94.115.100/items/recognitions');

              Gal.putImage(imagePath, album: "GuillaumeAI");
              showToast("Image enregistrée");
              HapticFeedback.vibrate();
              final Map<String, dynamic> data = {
                'device_id': deviceId,
                'path': imagePath,
              };

              try {
                final response = await http.post(
                  url,
                  headers: {
                    'Content-Type': 'application/json',
                  },
                  body: json.encode(data),
                );

                if (response.statusCode == 200 || response.statusCode == 201) {
                  final image = json.decode(response.body);
                  final int imageId = image['id'];

                  for (var element in results) {
                    final Map<String, dynamic> recognitionData = {
                      'image_id': imageId,
                      'recognition': element.label,
                      'confidence': element.score
                    };

                    try {
                      final recognitionResponse = await http.post(
                        recognitionUrl,
                        headers: {
                          'Content-Type': 'application/json',
                        },
                        body: json.encode(recognitionData),
                      );

                      if (recognitionResponse.statusCode == 200 ||
                          recognitionResponse.statusCode == 201) {
                      } else {
                        showToast(
                            "Failed to save recognition: ${recognitionResponse.statusCode}");
                      }
                    } catch (e) {
                      showToast("Error during recognition save: $e");
                    }
                  }

                  Gal.putImage(imagePath, album: "GuillaumeAI");
                  showToast("Image enregistrée");
                } else {
                  showToast(
                      "Failed to save image, status: ${response.statusCode}");
                }
              } catch (e) {
                showToast("Error: $e");
              }
            },
            icon: Icon(Icons.download),
          )
        ],
      ),
      body: Image.file(File(imagePath)),
    );
  }

  void showResults(BuildContext context) {
    String result = "";

    for (var element in results) {
      result += "- ${element.label} : ${element.score}\n";
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Resultats'),
          content: Text(result),
          actions: <Widget>[
            TextButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                HapticFeedback.vibrate();
              },
            ),
          ],
        );
      },
    );
  }

  Future<String?> _getDeviceId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      var iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor;
    } else if (Platform.isAndroid) {
      // ignore: unused_local_variable
      var androidDeviceInfo = await deviceInfo.androidInfo;
      return AndroidId().getId();
    }
    return null;
  }
}
