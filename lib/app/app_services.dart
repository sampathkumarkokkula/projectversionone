import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/clock.dart';
import '../core/ids.dart';
import '../data/crypto/argon2_hasher.dart';
import '../data/crypto/olm_crypto.dart';
import '../data/local/app_database.dart';
import '../data/local/device_key_store.dart';
import '../data/push/notifications.dart';
import '../data/push/push_service.dart';
import '../data/remote/supabase_backend.dart';
import '../domain/expiry_sweeper.dart';
import '../domain/lock_service.dart';
import '../domain/message_service.dart';
import '../domain/outbound.dart';
import '../domain/session_establisher.dart';
import '../domain/sync_engine.dart';
import '../domain/wipe_service.dart';
import 'account_service.dart';
import 'chat_actions.dart';

/// Composition root: every long-lived service, wired once at start-up.
class AppServices {
  AppServices._({
    required this.keyStore,
    required this.db,
    required this.backend,
    required this.crypto,
    required this.lock,
    required this.outbound,
    required this.messages,
    required this.sessions,
    required this.wipe,
    required this.sweeper,
    required this.sync,
    required this.account,
    required this.chatActions,
    required this.push,
    required this.notifications,
    required this.clock,
  });

  factory AppServices.create({
    required DeviceKeyStore keyStore,
    required AppDatabase db,
    required SupabaseClient client,
    required Uint8List pickleKey,
  }) {
    const clock = SystemClock();
    final ids = UuidV4Generator();
    final crypto = OlmCrypto(db: db, pickleKey: pickleKey, clock: clock);
    final backend = SupabaseBackend(client, deviceKey: crypto.identityKey);
    final lock = LockService(settings: db, hasher: const Argon2idHasher(), clock: clock);
    final outbound = Outbound(db: db, crypto: crypto, clock: clock, ids: ids);
    final messages = MessageService(db: db, crypto: crypto, outbound: outbound, clock: clock, ids: ids);
    final sessions = SessionEstablisher(db: db, directory: backend, crypto: crypto, messages: messages);
    final wipe = WipeService(db: db, outbound: outbound, clock: clock);
    final sweeper = ExpirySweeper(db: db, clock: clock);
    final sync = SyncEngine(
      db: db,
      relay: backend,
      directory: backend,
      messages: messages,
      sessions: sessions,
      wipe: wipe,
      clock: clock,
    );
    final account = AccountService(
      backend: backend,
      crypto: crypto,
      lock: lock,
      wipe: wipe,
      db: db,
      keyStore: keyStore,
      messages: messages,
    );
    return AppServices._(
      keyStore: keyStore,
      db: db,
      backend: backend,
      crypto: crypto,
      lock: lock,
      outbound: outbound,
      messages: messages,
      sessions: sessions,
      wipe: wipe,
      sweeper: sweeper,
      sync: sync,
      account: account,
      chatActions: ChatActions(backend: backend, messages: messages),
      push: PushService(),
      notifications: Notifications(),
      clock: clock,
    );
  }

  final DeviceKeyStore keyStore;
  final AppDatabase db;
  final SupabaseBackend backend;
  final OlmCrypto crypto;
  final LockService lock;
  final Outbound outbound;
  final MessageService messages;
  final SessionEstablisher sessions;
  final WipeService wipe;
  final ExpirySweeper sweeper;
  final SyncEngine sync;
  final AccountService account;
  final ChatActions chatActions;
  final PushService push;
  final Notifications notifications;
  final Clock clock;
}
