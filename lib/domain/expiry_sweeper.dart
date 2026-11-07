import 'package:drift/drift.dart';

import '../core/clock.dart';
import '../data/local/app_database.dart';
import 'models.dart';

/// Local enforcement of auto-delete timers.
///
/// Physically deletes every message whose expiry has passed. For messages
/// this device sent, the ids are remembered in `pending_deletes` so the main
/// isolate can relay an encrypted delete command to the peer (keeping both
/// phones in sync even if the peer's clock is behind). The sweep itself does
/// no networking and no encryption, so it can also run from a background
/// WorkManager task while the app is closed.
class ExpirySweeper {
  ExpirySweeper({required this.db, required this.clock});

  final AppDatabase db;
  final Clock clock;

  /// Returns the number of messages deleted.
  Future<int> sweep() => db.transaction(() async {
        final now = clock.nowMs();
        final expired = await (db.select(db.messages)
              ..where((m) => m.expiresAt.isNotNull() & m.expiresAt.isSmallerOrEqualValue(now)))
            .get();
        if (expired.isEmpty) return 0;
        for (final m in expired) {
          if (m.fromMe && m.kind == MessageKind.text.name) {
            await db.into(db.pendingDeletes).insertOnConflictUpdate(
                  PendingDeletesCompanion.insert(messageId: m.id, chatId: m.chatId),
                );
          }
        }
        await db.deleteMessagesByIds(expired.map((m) => m.id));
        return expired.length;
      });
}
