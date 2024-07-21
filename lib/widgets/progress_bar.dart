// ignore_for_file: use_super_parameters, prefer_const_constructors

import 'package:flutter/material.dart';

class CustomButtonWithStaticProgressBar extends StatelessWidget {
  final double height;
  final double width;
  final double progressValue;
  final VoidCallback? onTap;

  const CustomButtonWithStaticProgressBar({
    Key? key,
    required this.height,
    required this.width,
    required this.progressValue,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: LinearProgressIndicator(
        value: progressValue.clamp(0.0, 1.0), // Ensure value is between 0 and 1
        backgroundColor: Colors.grey[300],
        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
      ),
    );
  }
}
