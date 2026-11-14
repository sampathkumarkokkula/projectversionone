import '../data/local/app_database.dart';
import 'message_service.dart';
import 'models.dart';
import 'ports.dart';

/// The peer has no account any more.
class PeerGoneException implements Exception {
  const PeerGoneException();
}

/// The peer has no keys left to start a session (their phone has not
/// replenished one-time keys and has no fallback key).
class PeerUnavailableException implements Exception {
  const PeerUnavailableException();
}

/// The username belongs to the signed-in user.
class SelfChatException implements Exception {
  const SelfChatException();
}

/// Sets up Olm sessions on demand: claims one of the peer's signed one-time
/// keys from the directory and runs the handshake. Needs the network; every
/// other chat operation works offline once a session exists.
class SessionEstablisher {
  SessionEstablisher({
    required this.db,
    required this.directory,
    required this.crypto,
    required this.messages,
  });

  final AppDatabase db;
  final DirectoryApi directory;
  final E2eCrypto crypto;
  final MessageService messages;

  /// Opens (or re-opens) a chat with the exact [username]. Returns null when
  /// nobody has that username.
  Future<PeerKeys?> startChat(String username, {required String? selfId}) async {
    final peer = await directory.lookupUsername(username);
    if (peer == null) return null;
    if (peer.userId == selfId) throw const SelfChatException();
    final existing = await db.chatById(peer.userId);
    final keysChanged = existing != null && existing.peerIdentityKey != peer.identityKey;
    if (existing == null || keysChanged || !await crypto.hasSession(peer.userId)) {
      await _establish(peer);
    } else if (!existing.accepted) {
      // Starting a chat with someone who sent a request accepts it.
      await messages.acceptChat(peer.userId);
    }
    return peer;
  }

  /// Makes sure a session with [peerId] exists. With [force] a fresh session
  /// is set up even if one exists (repair after undecryptable messages).
  Future<void> ensure(String peerId, {bool force = false}) async {
    if (!force && await crypto.hasSession(peerId)) return;
    final peer = await directory.getUser(peerId);
    if (peer == null) throw const PeerGoneException();
    await _establish(peer);
  }

  Future<void> _establish(PeerKeys peer) async {
    final key = await directory.claimOneTimeKey(peer.userId);
    if (key == null) throw const PeerUnavailableException();
    await db.transaction(() async {
      await crypto.startSession(peer, key);
      await messages.ensureChat(peer);
      await messages.refreshPeerIdentity(peer);
    });
  }
}
