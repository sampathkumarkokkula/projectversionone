import 'dart:io';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'app_database.dart';

const String _fileName = 'bvm.sqlite';

Future<File> databaseFile() async {
  final dir = await getApplicationSupportDirectory();
  return File(p.join(dir.path, _fileName));
}

/// Opens (or creates) the SQLCipher-encrypted database with a raw 256-bit key.
///
/// Throws if SQLCipher is not linked or the key does not decrypt the file.
Future<AppDatabase> openEncryptedDatabase(String hexKey, {File? file}) async {
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(hexKey)) {
    throw ArgumentError('database key must be 64 lowercase hex characters');
  }
  final target = file ?? await databaseFile();
  final db = AppDatabase(
    NativeDatabase.createInBackground(target, setup: (raw) => applyCipherSettings(raw, hexKey)),
  );
  // Force the connection open now so a wrong key fails here, not later.
  await db.customSelect('SELECT count(*) FROM sqlite_master').get();
  return db;
}

/// Keys the connection and applies privacy settings. Must run first.
void applyCipherSettings(Database raw, String? hexKey) {
  final version = raw.select('PRAGMA cipher_version');
  if (version.isEmpty) {
    throw StateError('SQLCipher is not available; refusing to open an unencrypted database');
  }
  if (hexKey != null) {
    // Raw key syntax: the random key is used directly (no passphrase KDF).
    raw.execute("PRAGMA key = \"x'$hexKey'\"");
  }
  raw.execute('PRAGMA cipher_memory_security = ON');
  // Fails with "file is not a database" when the key is wrong.
  raw.select('SELECT count(*) FROM sqlite_master');
  // Overwrite deleted content instead of leaving it in free pages.
  raw.execute('PRAGMA secure_delete = ON');
  raw.execute('PRAGMA foreign_keys = ON');
  raw.execute('PRAGMA journal_mode = WAL');
  raw.execute('PRAGMA busy_timeout = 5000');
}

/// Deletes the database and its WAL/SHM side files.
Future<void> deleteDatabaseFiles({File? file}) async {
  final target = file ?? await databaseFile();
  for (final suffix in ['', '-wal', '-shm', '-journal']) {
    final f = File('${target.path}$suffix');
    if (await f.exists()) await f.delete();
  }
}
