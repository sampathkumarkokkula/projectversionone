import 'dart:convert';
import 'dart:io';

import 'package:bvm/data/local/database_opener.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// The local database must be SQLCipher-encrypted at rest.
void main() {
  late Directory dir;
  late File file;
  const key = '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff';
  const otherKey = 'ffeeddccbbaa99887766554433221100ffeeddccbbaa99887766554433221100';

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bvm_db_test');
    file = File(p.join(dir.path, 'bvm.sqlite'));
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('the file on disk is ciphertext and needs the key', () async {
    final db = await openEncryptedDatabase(key, file: file);
    await db.write('probe', 'PLAINTEXT-CANARY-4711');
    await db.close();

    for (final suffix in ['', '-wal']) {
      final f = File('${file.path}$suffix');
      if (!await f.exists()) continue;
      final raw = latin1.decode(await f.readAsBytes());
      expect(raw.contains('PLAINTEXT-CANARY'), isFalse, reason: '$suffix must not contain plaintext');
      expect(raw.startsWith('SQLite format 3'), isFalse, reason: 'plain SQLite header found');
    }

    await expectLater(openEncryptedDatabase(otherKey, file: file), throwsA(anything));

    final reopened = await openEncryptedDatabase(key, file: file);
    expect(await reopened.read('probe'), 'PLAINTEXT-CANARY-4711');
    await reopened.close();
  });
}
