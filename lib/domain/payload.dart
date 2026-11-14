import 'dart:convert';

/// Plaintext payloads carried inside the end-to-end-encrypted envelope.
///
/// The server only sees the relay `type` column (message, receipt, delete,
/// timer_change). A duress wipe is sent as type `delete`, the same type as a
/// routine timer-expiry deletion, so the server cannot tell them apart.
/// Every payload is padded to a multiple of [_padBlock] bytes before
/// encryption so ciphertext length reveals little about the content.
sealed class Payload {
  const Payload();

  /// Value for the relay table's `type` column.
  String get relayType;

  /// Whether the recipient should get a content-free wake-up push.
  bool get wantsPush => false;

  String get _kind;

  Map<String, Object?> _fields();

  static const int _padBlock = 256;

  /// JSON, padded with spaces to a multiple of 256 bytes.
  String encode() {
    final map = <String, Object?>{'v': 1, 'k': _kind, ..._fields(), 'p': ''};
    final unpadded = jsonEncode(map);
    final length = utf8.encode(unpadded).length;
    final remainder = length % _padBlock;
    if (remainder == 0) return unpadded;
    map['p'] = ' ' * (_padBlock - remainder);
    return jsonEncode(map);
  }

  /// Parses a decrypted payload. Returns [UnknownPayload] for anything that
  /// is malformed or comes from a newer app version.
  static Payload decode(String plaintext) {
    try {
      final map = jsonDecode(plaintext);
      if (map is! Map<String, Object?>) return const UnknownPayload();
      final kind = map['k'];
      switch (kind) {
        case 'text':
          final id = map['id'];
          final body = map['b'];
          final at = map['at'];
          final ttl = map['ttl'];
          if (id is! String || body is! String || at is! int) return const UnknownPayload();
          final reply = map['r'];
          return TextPayload(
            id: id,
            body: body,
            sentAt: at,
            ttlSeconds: ttl is int && ttl > 0 ? ttl : null,
            replyTo: reply is String ? reply : null,
          );
        case 'img':
          final id = map['id'];
          final part = map['i'];
          final total = map['n'];
          final at = map['at'];
          final ttl = map['ttl'];
          final width = map['w'];
          final height = map['h'];
          final sha = map['sha'];
          final data = map['d'];
          final reply = map['r'];
          if (id is! String ||
              part is! int ||
              total is! int ||
              at is! int ||
              width is! int ||
              height is! int ||
              sha is! String ||
              data is! String) {
            return const UnknownPayload();
          }
          if (total < 1 || total > ImagePartPayload.maxParts || part < 0 || part >= total) {
            return const UnknownPayload();
          }
          return ImagePartPayload(
            id: id,
            part: part,
            total: total,
            sentAt: at,
            ttlSeconds: ttl is int && ttl > 0 ? ttl : null,
            width: width,
            height: height,
            sha256: sha,
            data: data,
            replyTo: reply is String ? reply : null,
          );
        case 'profile':
          final version = map['pv'];
          final avatar = map['a'];
          if (version is! int || (avatar != null && avatar is! String)) return const UnknownPayload();
          return ProfilePayload(version: version, avatarBase64: avatar as String?);
        case 'receipt':
          final ids = _stringList(map['ids']);
          final st = map['st'];
          if (ids == null || (st != 'delivered' && st != 'read')) return const UnknownPayload();
          return ReceiptPayload(ids: ids, read: st == 'read');
        case 'delete':
          final ids = _stringList(map['ids']);
          return ids == null ? const UnknownPayload() : DeletePayload(ids: ids);
        case 'wipe':
          final before = map['before'];
          return before is int ? WipePayload(before: before) : const UnknownPayload();
        case 'timer':
          final ttl = map['ttl'];
          final at = map['at'];
          if (at is! int || (ttl != null && ttl is! int)) return const UnknownPayload();
          return TimerPayload(seconds: ttl as int?, changedAt: at);
        case 'hello':
          return const HelloPayload();
        default:
          return const UnknownPayload();
      }
    } on FormatException {
      return const UnknownPayload();
    }
  }

  static List<String>? _stringList(Object? value) {
    if (value is! List) return null;
    final out = <String>[];
    for (final v in value) {
      if (v is! String) return null;
      out.add(v);
    }
    return out;
  }
}

/// A chat message. [ttlSeconds] is the sender's auto-delete timer at the
/// moment of sending (`null` = never expires). [replyTo] is the id of the
/// message being answered; the quoted text itself is never re-sent, so a
/// reply cannot keep an expired message alive.
final class TextPayload extends Payload {
  const TextPayload({
    required this.id,
    required this.body,
    required this.sentAt,
    this.ttlSeconds,
    this.replyTo,
  });

  final String id;
  final String body;
  final int sentAt;
  final int? ttlSeconds;
  final String? replyTo;

  @override
  String get relayType => 'message';

  @override
  bool get wantsPush => true;

  @override
  String get _kind => 'text';

  @override
  Map<String, Object?> _fields() => {'id': id, 'b': body, 'at': sentAt, 'ttl': ttlSeconds, 'r': replyTo};
}

/// One part of a photo. A photo (already shrunk to at most ~300 KB JPEG) is
/// split into parts of [partBytes] so every part fits a normal relay envelope;
/// each part is Olm-encrypted like a text message and deleted from the server
/// once delivered. [sha256] covers the whole JPEG and is checked after the
/// parts are joined.
final class ImagePartPayload extends Payload {
  const ImagePartPayload({
    required this.id,
    required this.part,
    required this.total,
    required this.sentAt,
    required this.width,
    required this.height,
    required this.sha256,
    required this.data,
    this.ttlSeconds,
    this.replyTo,
  });

  /// Raw bytes per part. Keeps the double-base64 envelope under the relay's
  /// 64 KiB limit.
  static const int partBytes = 30 * 1024;
  static const int maxParts = 20;

  final String id;
  final int part;
  final int total;
  final int sentAt;
  final int width;
  final int height;
  final String sha256;

  /// Base64 of this part's bytes.
  final String data;
  final int? ttlSeconds;
  final String? replyTo;

  @override
  String get relayType => 'message';

  /// One wake-up per photo, not per part.
  @override
  bool get wantsPush => part == 0;

  @override
  String get _kind => 'img';

  @override
  Map<String, Object?> _fields() => {
        'id': id,
        'i': part,
        'n': total,
        'at': sentAt,
        'ttl': ttlSeconds,
        'w': width,
        'h': height,
        'sha': sha256,
        'd': data,
        'r': replyTo,
      };
}

/// The sender's profile picture (or its removal), sent only to people they
/// chat with. Also tells the receiver to re-read the sender's username from
/// the directory, so a changed username shows up without being trusted from
/// the message itself.
final class ProfilePayload extends Payload {
  const ProfilePayload({required this.version, this.avatarBase64});

  final int version;

  /// Base64 JPEG (at most ~24 KB), or null when the picture was removed.
  final String? avatarBase64;

  /// Travels as type `receipt`, so the server cannot tell profile updates
  /// apart from read receipts.
  @override
  String get relayType => 'receipt';

  @override
  String get _kind => 'profile';

  @override
  Map<String, Object?> _fields() => {'pv': version, 'a': avatarBase64};
}

/// Delivery or read receipt for messages the recipient sent.
final class ReceiptPayload extends Payload {
  const ReceiptPayload({required this.ids, required this.read});

  final List<String> ids;
  final bool read;

  @override
  String get relayType => 'receipt';

  @override
  String get _kind => 'receipt';

  @override
  Map<String, Object?> _fields() => {'ids': ids, 'st': read ? 'read' : 'delivered'};
}

/// Relayed deletion of specific messages (timer expiry), sent by the author.
final class DeletePayload extends Payload {
  const DeletePayload({required this.ids});

  final List<String> ids;

  @override
  String get relayType => 'delete';

  @override
  String get _kind => 'delete';

  @override
  Map<String, Object?> _fields() => {'ids': ids};
}

/// Wipe command: delete the whole conversation (secondary-password unlock).
final class WipePayload extends Payload {
  const WipePayload({required this.before});

  /// Sender's clock at the moment of the wipe; anything sent up to this time
  /// that arrives later is dropped as well.
  final int before;

  @override
  String get relayType => 'delete';

  @override
  String get _kind => 'wipe';

  @override
  Map<String, Object?> _fields() => {'before': before};
}

/// Auto-delete timer change, made by either participant.
final class TimerPayload extends Payload {
  const TimerPayload({required this.seconds, required this.changedAt});

  final int? seconds;
  final int changedAt;

  @override
  String get relayType => 'timer_change';

  @override
  String get _kind => 'timer';

  @override
  Map<String, Object?> _fields() => {'ttl': seconds, 'at': changedAt};
}

/// Establishes (or repairs) an Olm session without user-visible content.
final class HelloPayload extends Payload {
  const HelloPayload();

  @override
  String get relayType => 'receipt';

  @override
  String get _kind => 'hello';

  @override
  Map<String, Object?> _fields() => const {};
}

/// Anything this version does not understand. Never encoded.
final class UnknownPayload extends Payload {
  const UnknownPayload();

  @override
  String get relayType => 'receipt';

  @override
  String get _kind => 'unknown';

  @override
  Map<String, Object?> _fields() => const {};
}

/// What travels in `relay.ciphertext`: an Olm message and its type
/// (0 = pre-key message that sets up a session, 1 = normal message).
class WireEnvelope {
  const WireEnvelope({required this.olmType, required this.body});

  final int olmType;
  final String body;

  String encode() => jsonEncode({'v': 1, 't': olmType, 'c': body});

  static WireEnvelope? tryParse(String raw) {
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, Object?>) return null;
      final t = map['t'];
      final c = map['c'];
      if (t is! int || (t != 0 && t != 1) || c is! String || c.isEmpty) return null;
      return WireEnvelope(olmType: t, body: c);
    } on FormatException {
      return null;
    }
  }
}
