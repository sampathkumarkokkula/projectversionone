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
          return TextPayload(
            id: id,
            body: body,
            sentAt: at,
            ttlSeconds: ttl is int && ttl > 0 ? ttl : null,
          );
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
/// moment of sending (`null` = never expires).
final class TextPayload extends Payload {
  const TextPayload({
    required this.id,
    required this.body,
    required this.sentAt,
    this.ttlSeconds,
  });

  final String id;
  final String body;
  final int sentAt;
  final int? ttlSeconds;

  @override
  String get relayType => 'message';

  @override
  bool get wantsPush => true;

  @override
  String get _kind => 'text';

  @override
  Map<String, Object?> _fields() => {'id': id, 'b': body, 'at': sentAt, 'ttl': ttlSeconds};
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
