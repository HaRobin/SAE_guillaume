import 'dart:convert';
import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:native_exif/native_exif.dart';

import 'package:oktoast/oktoast.dart';

import 'package:photo_manager/photo_manager.dart';
import 'package:http/http.dart' as http;

class DisplayPictureFromHome extends StatelessWidget {
  final AssetEntity image;

  const DisplayPictureFromHome({super.key, required this.image});

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
        ],
      ),
      body: FutureBuilder(
        future: image.file,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ListTile(title: Text('Loading...'));
          }
          final file = snapshot.data!;

          return Scaffold(
            body: Image.file(file),
          );
        },
      ),
    );
  }

  Future<void> showResults(BuildContext context) async {
    String result = "";

    String deviceId = "unknown";
    String? maybeDeviceId = await _getDeviceId();
    if (maybeDeviceId != null) {
      deviceId = maybeDeviceId;
    }

// Fetch images
    // ignore: prefer_interpolation_to_compose_strings
    final url = Uri.parse('http://141.94.115.100/items/images/' + deviceId);
    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final images = json.decode(resp.body);

        // Filter images
        var thefile = await image.file;
        var splittedPath = thefile!.path.split("/");
        var baseFileName = splittedPath.last;

        final filteredImages = images
            .where((animage) => animage['path'].split("/").last == baseFileName)
            .toList();

        if (filteredImages.isEmpty) {
          // ignore: prefer_interpolation_to_compose_strings
          showToast('No images found with the specified path : ' + baseFileName);
          return;
        }

        final theImage = filteredImages.first;

        final recognitionsURL = Uri.parse(
            // ignore: prefer_interpolation_to_compose_strings
            'http://141.94.115.100/items/recognitions/' +
                theImage['id'].toString());
        final recognitionResp = await http.get(recognitionsURL);

        if (recognitionResp.statusCode == 200) {
          final recognitions = json.decode(recognitionResp.body);

          for (var elem in recognitions) {
            result += "${elem['recognition']} : ${elem['confidence']}\n";
          }
        } else {
          showToast(
              'Failed to fetch recognitions: ${recognitionResp.statusCode}');
          return;
        }
      } else {
        showToast('Failed to fetch images: ${resp.statusCode}');
        return;
      }
    } catch (e) {
      showToast('Error during API calls: $e');
      return;
    }

// Show dialog
    if (!context.mounted) {
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Résultats'),
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
