import '../data/remote/supabase_backend.dart';
import '../domain/message_service.dart';

/// Safety actions that need both the server and the local database.
class ChatActions {
  ChatActions({required this.backend, required this.messages});

  final SupabaseBackend backend;
  final MessageService messages;

  /// The server drops their envelopes from now on; they are not told.
  Future<void> block(String peerId) async {
    await backend.blockUser(peerId);
    await messages.setBlocked(peerId, true);
  }

  Future<void> unblock(String peerId) async {
    await backend.unblockUser(peerId);
    await messages.setBlocked(peerId, false);
  }

  /// Reports the account as spam (which also blocks it) and deletes the chat
  /// from this phone. Several reports from different people suspend the
  /// account and ban its e-mail address.
  Future<void> reportSpam(String peerId) async {
    await backend.reportSpam(peerId);
    await messages.deleteChat(peerId);
  }

  /// Deletes the chat from this phone only.
  Future<void> deleteChat(String peerId) => messages.deleteChat(peerId);
}
