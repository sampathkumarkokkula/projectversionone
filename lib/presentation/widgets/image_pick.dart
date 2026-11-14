import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Lets the user pick a photo from the gallery or take one with the camera
/// app. Returns the raw bytes (null when cancelled). The temporary copy the
/// picker leaves in the app cache is deleted right away.
///
/// Uses the system photo picker (no storage permission) and the camera app
/// (no camera permission in BVM itself).
Future<Uint8List?> pickImage(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;
  final file = await ImagePicker().pickImage(
    source: source,
    // First, cheap native downscale; BVM then re-encodes and strips metadata.
    maxWidth: 2048,
    maxHeight: 2048,
    imageQuality: 90,
    requestFullMetadata: false,
  );
  if (file == null) return null;
  try {
    return await file.readAsBytes();
  } finally {
    try {
      await File(file.path).delete();
    } on Object {
      // Already gone.
    }
  }
}
