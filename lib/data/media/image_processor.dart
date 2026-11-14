import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// A JPEG ready to send or store.
class ProcessedImage {
  const ProcessedImage(this.bytes, this.width, this.height);

  final Uint8List bytes;
  final int width;
  final int height;
}

/// The picked file is not an image this app can read.
class UnsupportedImageException implements Exception {
  const UnsupportedImageException();
}

/// Re-encodes pictures before they are encrypted:
///
/// * applies the camera rotation, then drops **all metadata** (EXIF with GPS
///   location, camera model and time, ICC profile, text chunks);
/// * shrinks photos to at most [photoMaxSide] px and about [photoTargetBytes]
///   (typically 100-300 KB), profile pictures to a [avatarSide] px square of
///   about [avatarTargetBytes], so the encrypted parts on the server stay
///   small and short-lived.
///
/// Runs on a separate isolate; pure Dart (package:image), no native code.
abstract final class ImageProcessor {
  static const int photoMaxSide = 1600;
  static const int photoTargetBytes = 300 * 1024;
  static const int avatarSide = 256;
  static const int avatarTargetBytes = 24 * 1024;

  static Future<ProcessedImage> preparePhoto(Uint8List input) =>
      Isolate.run(() => _process(input, maxSide: photoMaxSide, targetBytes: photoTargetBytes, square: false));

  static Future<ProcessedImage> prepareAvatar(Uint8List input) =>
      Isolate.run(() => _process(input, maxSide: avatarSide, targetBytes: avatarTargetBytes, square: true));

  static ProcessedImage _process(Uint8List input, {required int maxSide, required int targetBytes, required bool square}) {
    final decoded = img.decodeImage(input);
    if (decoded == null) throw const UnsupportedImageException();
    // First frame of animations; then apply the camera rotation.
    img.Image image = decoded.frames.length > 1 ? decoded.frames.first : decoded;
    image = img.bakeOrientation(image);

    if (square) {
      final side = min(image.width, image.height);
      image = img.copyCrop(image, x: (image.width - side) ~/ 2, y: (image.height - side) ~/ 2, width: side, height: side);
    }
    image = _fit(image, maxSide);

    // Nothing but pixels leaves the phone.
    image.exif = img.ExifData();
    image.iccProfile = null;
    image.textData = null;

    var quality = 80;
    var out = img.encodeJpg(image, quality: quality);
    while (out.length > targetBytes && quality > 45) {
      quality -= 10;
      out = img.encodeJpg(image, quality: quality);
    }
    while (out.length > targetBytes && max(image.width, image.height) > 320) {
      image = _fit(image, (max(image.width, image.height) * 0.75).round());
      out = img.encodeJpg(image, quality: quality);
    }
    return ProcessedImage(out, image.width, image.height);
  }

  static img.Image _fit(img.Image image, int maxSide) {
    if (max(image.width, image.height) <= maxSide) return image;
    return image.width >= image.height
        ? img.copyResize(image, width: maxSide, interpolation: img.Interpolation.average)
        : img.copyResize(image, height: maxSide, interpolation: img.Interpolation.average);
  }
}
