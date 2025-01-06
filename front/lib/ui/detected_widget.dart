import 'package:flutter/widgets.dart';

/// Row for one Stats field
class DetectedWidget extends StatelessWidget {
  final String left;
  final String middle;
  final String right;

  const DetectedWidget(this.left, this.middle, this.right, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(left, overflow: TextOverflow.ellipsis)),
            Expanded(
                child: Text(middle,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center)),
            Expanded(
                child: Text(right,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right)),
          ],
        ),
      );
}
