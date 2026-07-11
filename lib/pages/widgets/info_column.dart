import 'package:flutter/material.dart';
import 'package:tf_news/pages/widgets/info_choises.dart';

class InfoColumn extends StatelessWidget {
  const InfoColumn({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        border: Border.fromBorderSide(
          BorderSide(color: Colors.grey[300]!),
        ),
        color: Colors.grey[200],
      ),
      child: InfoChoises(),
    );
  }
}