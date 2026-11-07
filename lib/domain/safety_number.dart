import 'dart:convert';

import 'package:hashlib/hashlib.dart' show sha512;

/// Safety number for a chat: 60 digits derived from both participants'
/// Ed25519 identity keys. Both phones show the same number; comparing it in
/// person (or over a call) detects a server swapping keys.
String safetyNumber(String signingKeyA, String signingKeyB) {
  final keys = [signingKeyA, signingKeyB]..sort();
  final digest = sha512.convert(utf8.encode('bvm-safety-number-v1|${keys[0]}|${keys[1]}')).bytes;
  final groups = <String>[];
  for (var i = 0; i < 12; i++) {
    var value = 0;
    for (var j = 0; j < 5; j++) {
      value = (value << 8) | digest[i * 5 + j];
    }
    groups.add((value % 100000).toString().padLeft(5, '0'));
  }
  return groups.join(' ');
}
