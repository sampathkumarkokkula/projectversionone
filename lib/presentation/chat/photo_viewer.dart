import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Full-screen photo with pinch-zoom. There is deliberately no "save" or
/// "share": photos stay inside BVM's encrypted storage (and screenshots are
/// blocked).
class PhotoViewer extends StatelessWidget {
  const PhotoViewer({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
