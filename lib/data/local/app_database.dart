import 'package:drift/drift.dart';

import '../../domain/models.dart';
import '../../domain/ports.dart';

part 'app_database.g.dart';

/// One row per 1-to-1 conversation. The peer's user id is the chat id.
class Chats extends Table {
  TextColumn get peerId => text()();
  TextColumn get peerUsername => text()();

  /// Pinned (trust-on-first-use) identity keys of the peer.
  TextColumn get peerIdentityKey => text()();
  TextColumn get peerSigningKey => text()();

  /// Auto-delete timer in seconds; null = off.
  IntColumn get timerSeconds => integer().nullable()();
  IntColumn get timerChangedAt => integer().withDefault(const Constant(0))();

  /// Messages sent at or before this time are dropped if they arrive late
  /// (set by a wipe).
  IntColumn get wipedBefore => integer().nullable()();

  IntColumn get createdAt => integer()();
  IntColumn get lastActivityAt => integer()();

  // ---- schema v2 ----

  /// Blocked by this user (also enforced on the server).
  BoolColumn get blocked => boolean().withDefault(const Constant(false))();

  /// False for a chat someone else started ("message request") until this
  /// user accepts or replies. No receipts and no profile picture go to a
  /// request.
  BoolColumn get accepted => boolean().withDefault(const Constant(true))();

  /// Own profile version last sent to this peer.
  IntColumn get profileSentVersion => integer().withDefault(const Constant(0))();

  /// The peer announced a profile change; re-read their username.
  BoolColumn get refreshProfile => boolean().withDefault(const Constant(false))();

  /// Last time the peer's username was checked against the directory.
  IntColumn get directoryCheckedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {peerId};
}

class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get chatId => text().references(Chats, #peerId, onDelete: KeyAction.cascade)();
  BoolColumn get fromMe => boolean()();

  /// [MessageKind] name.
  TextColumn get kind => text()();
  TextColumn get body => text()();

  /// Sender's clock.
  IntColumn get sentAt => integer()();

  /// This device's clock when the row was created (display order).
  IntColumn get localAt => integer()();

  /// When the auto-delete sweep removes the message; null = never.
  IntColumn get expiresAt => integer().nullable()();

  /// [MessageStatus] name.
  TextColumn get status => text()();

  /// Id of the message this one replies to (schema v2).
  TextColumn get replyTo => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// JPEG bytes of a photo message. Deleted together with its message.
@DataClassName('MediaItem')
class Media extends Table {
  TextColumn get messageId => text().references(Messages, #id, onDelete: KeyAction.cascade)();
  BlobColumn get bytes => blob()();
  IntColumn get width => integer()();
  IntColumn get height => integer()();

  @override
  Set<Column<Object>> get primaryKey => {messageId};
}

/// Parts of an incoming photo until all of them have arrived.
class MediaParts extends Table {
  TextColumn get messageId => text()();
  IntColumn get part => integer()();
  TextColumn get chatId => text()();
  IntColumn get total => integer()();
  BlobColumn get data => blob()();
  IntColumn get sentAt => integer()();
  IntColumn get ttlSeconds => integer().nullable()();
  IntColumn get width => integer()();
  IntColumn get height => integer()();
  TextColumn get sha256 => text()();
  TextColumn get replyTo => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {messageId, part};
}

/// Profile pictures: own one under [selfAvatarId], peers' ones under their id.
class Avatars extends Table {
  TextColumn get ownerId => text()();
  BlobColumn get bytes => blob()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {ownerId};
}

const String selfAvatarId = 'self';

/// Pickled (encrypted with the Olm pickle key) Olm sessions.
class OlmSessions extends Table {
  TextColumn get sessionId => text()();
  TextColumn get peerId => text()();
  TextColumn get pickle => text()();
  IntColumn get lastUsedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {sessionId};
}

/// Encrypted envelopes waiting to be handed to the relay (offline queue).
@DataClassName('OutboxEntry')
class Outbox extends Table {
  /// Also the relay row id, which makes retries idempotent.
  TextColumn get id => text()();
  TextColumn get recipientId => text()();
  TextColumn get type => text()();
  TextColumn get envelope => text()();
  IntColumn get expiresAt => integer().nullable()();
  TextColumn get messageId => text().nullable()();
  BoolColumn get push => boolean()();
  IntColumn get createdAt => integer()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Ids of expired messages this device sent, waiting to be relayed as a
/// delete command to the peer (the background sweep cannot encrypt).
class PendingDeletes extends Table {
  TextColumn get messageId => text()();
  TextColumn get chatId => text()();

  @override
  Set<Column<Object>> get primaryKey => {messageId};
}

/// Relay ids already handled, so a lost acknowledgement never replays.
class ProcessedEnvelopes extends Table {
  TextColumn get id => text()();
  IntColumn get processedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Settings, password verifiers, the pickled Olm account, own profile.
class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// A chat with its newest message, for the chat list.
class ChatSummary {
  const ChatSummary(this.chat, this.lastMessage);

  final Chat chat;
  final Message? lastMessage;
}

/// A search hit: the message and the chat it belongs to.
class SearchHit {
  const SearchHit(this.message, this.chat);

  final Message message;
  final Chat chat;
}

@DriftDatabase(
  tables: [
    Chats,
    Messages,
    Media,
    MediaParts,
    Avatars,
    OlmSessions,
    Outbox,
    PendingDeletes,
    ProcessedEnvelopes,
    KeyValues,
  ],
)
class AppDatabase extends _$AppDatabase implements LocalSettings {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(chats, chats.blocked);
            await m.addColumn(chats, chats.accepted);
            await m.addColumn(chats, chats.profileSentVersion);
            await m.addColumn(chats, chats.refreshProfile);
            await m.addColumn(chats, chats.directoryCheckedAt);
            await m.addColumn(messages, messages.replyTo);
            await m.createTable(media);
            await m.createTable(mediaParts);
            await m.createTable(avatars);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // ---------------------------------------------------------------------------
  // Key/value settings
  // ---------------------------------------------------------------------------

  @override
  Future<String?> read(String key) async {
    final row = await (select(keyValues)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> write(String key, String value) =>
      into(keyValues).insertOnConflictUpdate(KeyValuesCompanion.insert(key: key, value: value));

  @override
  Future<void> remove(String key) => (delete(keyValues)..where((t) => t.key.equals(key))).go();

  Future<List<KeyValue>> valuesWithPrefix(String prefix) =>
      (select(keyValues)..where((t) => t.key.like('$prefix%'))).get();

  // ---------------------------------------------------------------------------
  // Chats
  // ---------------------------------------------------------------------------

  Future<Chat?> chatById(String peerId) =>
      (select(chats)..where((t) => t.peerId.equals(peerId))).getSingleOrNull();

  Stream<Chat?> watchChat(String peerId) =>
      (select(chats)..where((t) => t.peerId.equals(peerId))).watchSingleOrNull();

  Future<List<Chat>> timerChats() => (select(chats)..where((t) => t.timerSeconds.isNotNull())).get();

  Future<int> countTimerChats({String? excluding}) async {
    final query = selectOnly(chats)..addColumns([chats.peerId.count()]);
    query.where(chats.timerSeconds.isNotNull());
    if (excluding != null) query.where(chats.peerId.equals(excluding).not());
    final row = await query.getSingle();
    return row.read(chats.peerId.count()) ?? 0;
  }

  Future<void> touchChat(String peerId, int at) =>
      (update(chats)..where((t) => t.peerId.equals(peerId))).write(ChatsCompanion(lastActivityAt: Value(at)));

  /// Chats ordered by recent activity, each with its newest message. The join
  /// makes the stream re-emit when either table changes.
  Stream<List<ChatSummary>> watchChatSummaries() {
    final inner = alias(messages, 'newest');
    final newestId = subqueryExpression<String>(
      selectOnly(inner)
        ..addColumns([inner.id])
        ..where(inner.chatId.equalsExp(chats.peerId))
        ..orderBy([OrderingTerm.desc(inner.localAt)])
        ..limit(1),
    );
    final query = select(chats).join([leftOuterJoin(messages, messages.id.equalsExp(newestId))])
      ..orderBy([OrderingTerm.desc(chats.lastActivityAt)]);
    return query.watch().map(
          (rows) => [
            for (final row in rows) ChatSummary(row.readTable(chats), row.readTableOrNull(messages)),
          ],
        );
  }

  // ---------------------------------------------------------------------------
  // Messages
  // ---------------------------------------------------------------------------

  /// Newest first. Messages past their expiry are hidden even before the
  /// sweep physically deletes them.
  Stream<List<Message>> watchMessages(String chatId, {required int Function() now}) {
    return (select(messages)
          ..where((m) => m.chatId.equals(chatId))
          ..orderBy([(m) => OrderingTerm.desc(m.localAt), (m) => OrderingTerm.desc(m.sentAt)]))
        .watch()
        .map((rows) {
      final t = now();
      return rows.where((m) => m.expiresAt == null || m.expiresAt! > t).toList();
    });
  }

  Future<void> deleteMessagesByIds(Iterable<String> ids) async {
    final list = ids.toList();
    for (var i = 0; i < list.length; i += 500) {
      final chunk = list.sublist(i, i + 500 > list.length ? list.length : i + 500);
      await (delete(messages)..where((m) => m.id.isIn(chunk))).go();
    }
  }

  Future<void> deleteAllMessagesOf(String chatId) =>
      (delete(messages)..where((m) => m.chatId.equals(chatId))).go();

  /// Emits the value of a key/value setting whenever it changes.
  Stream<String?> watchValue(String key) =>
      (select(keyValues)..where((t) => t.key.equals(key))).watchSingleOrNull().map((row) => row?.value);

  Future<void> setStatus(String messageId, MessageStatus status) =>
      (update(messages)..where((m) => m.id.equals(messageId))).write(MessagesCompanion(status: Value(status.name)));

  Future<Message?> messageById(String id) =>
      (select(messages)..where((m) => m.id.equals(id))).getSingleOrNull();

  /// Text messages containing [query] (case-insensitive for ASCII), newest
  /// first, optionally within one chat. Expired messages are excluded.
  Future<List<SearchHit>> searchMessages(String query, {String? chatId, required int now, int limit = 100}) {
    final escaped = query.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
    final q = select(messages).join([innerJoin(chats, chats.peerId.equalsExp(messages.chatId))])
      ..where(messages.kind.equals(MessageKind.text.name) &
          messages.body.like('%$escaped%', escapeChar: r'\') &
          (messages.expiresAt.isNull() | messages.expiresAt.isBiggerThanValue(now)))
      ..orderBy([OrderingTerm.desc(messages.localAt)])
      ..limit(limit);
    if (chatId != null) q.where(messages.chatId.equals(chatId));
    return q.get().then((rows) => [
          for (final row in rows) SearchHit(row.readTable(messages), row.readTable(chats)),
        ]);
  }

  // ---------------------------------------------------------------------------
  // Photos and profile pictures
  // ---------------------------------------------------------------------------

  Future<MediaItem?> mediaOf(String messageId) =>
      (select(media)..where((m) => m.messageId.equals(messageId))).getSingleOrNull();

  Stream<Uint8List?> watchAvatar(String ownerId) => (select(avatars)..where((a) => a.ownerId.equals(ownerId)))
      .watchSingleOrNull()
      .map((row) => row?.bytes);

  Future<Uint8List?> avatarOf(String ownerId) async =>
      (await (select(avatars)..where((a) => a.ownerId.equals(ownerId))).getSingleOrNull())?.bytes;

  Future<void> setAvatar(String ownerId, Uint8List bytes, int at) => into(avatars).insertOnConflictUpdate(
        AvatarsCompanion.insert(ownerId: ownerId, bytes: bytes, updatedAt: at),
      );

  Future<void> removeAvatar(String ownerId) => (delete(avatars)..where((a) => a.ownerId.equals(ownerId))).go();

  Future<void> deletePartsOfChat(String chatId) =>
      (delete(mediaParts)..where((p) => p.chatId.equals(chatId))).go();

  // ---------------------------------------------------------------------------
  // Outbox
  // ---------------------------------------------------------------------------

  Future<List<OutboxEntry>> outboxInOrder({int limit = 200}) => (select(outbox)
        ..orderBy([
          (o) => OrderingTerm.asc(o.createdAt),
          (_) => OrderingTerm.asc(const CustomExpression<int>('rowid')),
        ])
        ..limit(limit))
      .get();

  Future<bool> hasOutboxFor(String messageId) async =>
      (await (select(outbox)
                ..where((o) => o.messageId.equals(messageId))
                ..limit(1))
              .get())
          .isNotEmpty;

  Future<void> removeOutbox(String id) => (delete(outbox)..where((o) => o.id.equals(id))).go();

  /// Drops queued envelopes of the given relay types for one peer.
  Future<void> dropOutboxFor(String peerId, List<String> types) =>
      (delete(outbox)..where((o) => o.recipientId.equals(peerId) & o.type.isIn(types))).go();

  // ---------------------------------------------------------------------------
  // Processed envelope ids
  // ---------------------------------------------------------------------------

  Future<bool> wasProcessed(String relayId) async =>
      (await (select(processedEnvelopes)..where((p) => p.id.equals(relayId))).getSingleOrNull()) != null;

  Future<void> markProcessed(String relayId, int at) => into(processedEnvelopes).insert(
        ProcessedEnvelopesCompanion.insert(id: relayId, processedAt: at),
        mode: InsertMode.insertOrIgnore,
      );

  Future<void> pruneProcessed(int olderThan) =>
      (delete(processedEnvelopes)..where((p) => p.processedAt.isSmallerThanValue(olderThan))).go();
}
