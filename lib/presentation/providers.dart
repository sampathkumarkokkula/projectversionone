import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_runtime.dart';
import '../app/app_services.dart';
import '../data/local/app_database.dart';

/// Riverpod is the single state manager: compile-time-safe dependency
/// injection plus reactive streams, no BuildContext needed, and every
/// provider can be overridden in tests.
final servicesProvider = Provider<AppServices>(
  (ref) => throw StateError('servicesProvider must be overridden at start-up'),
);

/// Whether the account was fully set up when the app started.
final setupCompleteProvider = Provider<bool>((ref) => false);

final runtimeProvider = Provider<AppRuntime>((ref) {
  final runtime = AppRuntime(ref.watch(servicesProvider));
  ref.onDispose(runtime.stop);
  return runtime;
});

final chatSummariesProvider = StreamProvider<List<ChatSummary>>(
  (ref) => ref.watch(servicesProvider).db.watchChatSummaries(),
);

final chatProvider = StreamProvider.autoDispose.family<Chat?, String>(
  (ref, chatId) => ref.watch(servicesProvider).db.watchChat(chatId),
);

final messagesProvider = StreamProvider.autoDispose.family<List<Message>, String>((ref, chatId) {
  final services = ref.watch(servicesProvider);
  return services.db.watchMessages(chatId, now: services.clock.nowMs);
});

final usernameProvider = FutureProvider<String?>(
  (ref) => ref.watch(servicesProvider).account.username(),
);

/// True once the server reported that the account moved to another phone.
final deviceReplacedProvider = StreamProvider<bool>(
  (ref) => ref.watch(servicesProvider).account.watchDeviceReplaced(),
);
