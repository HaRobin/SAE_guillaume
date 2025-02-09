import 'dart:convert';
import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
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
      // ignore: unnecessary_cast
      deviceId = maybeDeviceId as String;
    }

    // ignore: prefer_interpolation_to_compose_strings
    final url = Uri.parse('http://141.94.115.100/items/images/' + deviceId);

    final resp = await http.get(url);
    final images = json.decode(resp.body);

    final filteredImages = images.where((image) => image['path'] == image.file!.path).toList();

    final theImage = filteredImages.first;

    // ignore: prefer_interpolation_to_compose_strings
    final recognitionsURL = Uri.parse('http://141.94.115.100/items/images/' + theImage['id']); 

    final recognitionResp = await http.get(recognitionsURL);
    final recognitions = json.decode(recognitionResp.body);

    for(var elem in recognitions){
      result += "${elem['recognition']} : ${elem['confidence']}\n";
    }

    if (!context.mounted) {
      return;
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
