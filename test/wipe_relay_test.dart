import 'package:bvm/data/local/app_database.dart';
import 'package:bvm/domain/payload.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

/// Secondary-password wipe: local deletion, an end-to-end-encrypted wipe
/// command queued while offline, relayed when online, executed on the peer.
void main() {
  const day = 86400;
  late FakeClock clock;
  late FakeRelayServer server;
  late FakeDirectory directory;
  late Device alice;
  late Device bob;

  setUp(() async {
    clock = FakeClock(DateTime.utc(2026, 10, 31, 9).millisecondsSinceEpoch);
    server = FakeRelayServer();
    directory = FakeDirectory(server)
      ..add(peer('alice'))
      ..add(peer('bob'))
      ..add(peer('carol'));
    alice = Device('alice', server, directory, clock);
    bob = Device('bob', server, directory, clock);

    // alice <-> bob: auto-delete timer on both phones. alice <-> carol: none.
    await alice.connect('bob', timerSeconds: day);
    await bob.connect('alice', timerSeconds: day);
    await alice.connect('carol');

    await alice.messages.sendText('bob', 'first');
    await alice.messages.sendText('bob', 'second');
    await alice.messages.sendText('carol', 'not timed');
    await alice.sync.sync();
    await bob.sync.sync();
    await bob.messages.sendText('alice', 'reply');
    await bob.sync.sync();
    await alice.sync.sync();
  });

  tearDown(() async {
    await alice.close();
    await bob.close();
  });

  Future<int> textCount(Device d, String peerId) async =>
      (await d.messagesWith(peerId)).where((m) => m.kind == 'text').length;

  // Carol is not simulated, so her envelope stays queued on the server.
  Iterable<RelayRow> queuedFor(String userId) => server.rows.where((r) => r.recipientId == userId);

  test('wipe deletes timer chats on both phones, even when sent while offline', () async {
    expect(await textCount(alice, 'bob'), 3);
    expect(await textCount(bob, 'alice'), 3);
    server.pushRequests.clear();

    // Secondary-password unlock while the relay is unreachable.
    server.online = false;
    clock.advance(const Duration(minutes: 1));
    final wiped = await alice.wipe.duressWipe();
    expect(wiped, 1);

    // Local effect is immediate: the whole timer chat is gone, the other stays.
    expect(await alice.messagesWith('bob'), isEmpty);
    expect(await textCount(alice, 'carol'), 1);
    final aliceChat = await alice.db.chatById('bob');
    expect(aliceChat, isNotNull, reason: 'the chat entry stays, only the conversation goes');
    expect(aliceChat!.timerSeconds, day);

    // The command is queued, encrypted for bob, and survives the failed flush.
    await alice.sync.sync();
    final queued = await alice.outbox();
    expect(queued, hasLength(1));
    expect(queued.single.type, 'delete', reason: 'indistinguishable from a routine expiry delete');
    final opened = FakeCrypto.open(queued.single.envelope);
    expect(opened.to, 'bob');
    expect(opened.payload, isA<WipePayload>());
    expect(server.rows.where((r) => r.type == 'delete'), isEmpty);

    // Back online: relayed and held by the server until bob collects it.
    server.online = true;
    await alice.sync.sync();
    expect(await alice.outbox(), isEmpty);
    expect(queuedFor('bob').where((r) => r.type == 'delete'), hasLength(1));
    expect(server.pushRequests, isEmpty, reason: 'wipe commands do not trigger a visible notification');

    // Bob's phone executes it and the server forgets everything addressed to him.
    await bob.sync.sync();
    expect(await bob.messagesWith('alice'), isEmpty);
    expect(queuedFor('bob'), isEmpty);
  });

  test('messages sent before the wipe that arrive later are dropped', () async {
    // Bob writes while alice is wiping; his message is still in transit.
    await bob.messages.sendText('alice', 'in flight');
    await bob.sync.sync();

    clock.advance(const Duration(seconds: 5));
    await alice.wipe.duressWipe();
    await alice.sync.sync();

    expect(await alice.messagesWith('bob'), isEmpty);
    await bob.sync.sync();
    expect(await bob.messagesWith('alice'), isEmpty);

    // A message written after the wipe is delivered normally.
    clock.advance(const Duration(seconds: 5));
    await bob.messages.sendText('alice', 'after the wipe');
    await bob.sync.sync();
    await alice.sync.sync();
    expect((await alice.messagesWith('bob')).map((m) => m.body), ['after the wipe']);
  });

  test('a wipe for a timer chat without a session is sent once a session is set up', () async {
    // Dave's chat has a timer but no Olm session (for example right after
    // this phone got new keys).
    directory.add(peer('dave'));
    await alice.connect('dave', timerSeconds: day);
    alice.crypto.sessions.remove('dave');
    await alice.db.into(alice.db.messages).insert(
          MessagesCompanion.insert(
            id: 'old-dave-message',
            chatId: 'dave',
            fromMe: true,
            kind: 'text',
            body: 'secret',
            sentAt: clock.now,
            localAt: clock.now,
            status: 'delivered',
          ),
        );

    server.online = false;
    expect(await alice.wipe.duressWipe(), 2);
    expect(await alice.messagesWith('dave'), isEmpty, reason: 'the local wipe never waits for the network');
    expect(await alice.wipe.pendingWipes(), contains('dave'));

    // Offline: nothing can be set up yet, the command stays remembered.
    await alice.sync.sync();
    expect(await alice.wipe.pendingWipes(), contains('dave'));

    // Online: the sync claims one of Dave's keys, sets up the session and
    // relays the wipe command end-to-end encrypted.
    server.online = true;
    await alice.sync.sync();
    expect(await alice.wipe.pendingWipes(), isEmpty);
    final toDave = queuedFor('dave').toList();
    expect(toDave, hasLength(1));
    expect(toDave.single.type, 'delete');
    final opened = FakeCrypto.open(toDave.single.ciphertext);
    expect(opened.to, 'dave');
    expect(opened.payload, isA<WipePayload>());
  });

  test('forgot-password wipe is local only', () async {
    await alice.wipe.wipeBeforePasswordReset();
    expect(await alice.messagesWith('bob'), isEmpty);
    expect(await alice.outbox(), isEmpty);
    await alice.sync.sync();
    await bob.sync.sync();
    expect(await textCount(bob, 'alice'), 3);
  });

  test('a peer can change the timer and both phones show a notice', () async {
    await bob.messages.setTimer('alice', null);
    await bob.sync.sync();
    await alice.sync.sync();

    final chat = await alice.db.chatById('bob');
    expect(chat!.timerSeconds, isNull);
    final notices = (await alice.messagesWith('bob')).where((m) => m.kind == 'system').map((m) => m.body);
    expect(notices, contains('bob turned off the auto-delete timer.'));
    final bobNotices = (await bob.messagesWith('alice')).where((m) => m.kind == 'system').map((m) => m.body);
    expect(bobNotices, contains('You turned off the auto-delete timer.'));
  });

  test('delivery receipts flow back and delivered envelopes leave the relay', () async {
    final sent = (await alice.messagesWith('bob')).where((m) => m.fromMe).toList();
    expect(sent, hasLength(2));
    expect(sent.map((m) => m.status), everyElement('delivered'));
    expect(queuedFor('alice'), isEmpty);
  });
}
