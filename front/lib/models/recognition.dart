import 'package:flutter/cupertino.dart';
import 'package:front/models/screen_params.dart';

/// Represents the recognition output from the model
class Recognition {
  /// Index of the result
  final int _id;

  /// Label of the result
  final String _label;

  /// Confidence [0.0, 1.0]
  final double _score;

  /// Location of bounding box rect
  ///
  /// The rectangle corresponds to the raw input image
  /// passed for inference
  final Rect _location;

  Recognition(this._id, this._label, this._score, this._location);

  int get id => _id;

  String get label => _label;

  double get score => _score;

  Rect get location => _location;

  Rect get renderLocation {
    final double scaleX = ScreenParams.screenPreviewSize.width / 720;
    final double scaleY = ScreenParams.screenPreviewSize.height / 1280;

    final rect = Rect.fromLTWH(
      location.left * scaleX - 15,
      location.top * scaleY - 15,
      location.width * scaleX + 5,
      location.height * scaleY + 5,
    );

    debugPrint(rect.toString());
    return rect;
  }

  @override
  String toString() {
    return 'Recognition(id: $id, label: $label, score: $score, location: $location)';
  }
}
