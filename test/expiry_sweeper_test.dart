import 'package:bvm/domain/expiry_sweeper.dart';
import 'package:bvm/domain/payload.dart';
import 'package:bvm/domain/ports.dart';
import 'package:bvm/domain/timer_policy.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  const hour = Duration(hours: 1);
  late FakeClock clock;
  late FakeRelayServer server;
  late FakeDirectory directory;
  late Device alice;
  late ExpirySweeper sweeper;

  setUp(() async {
    clock = FakeClock(DateTime.utc(2026, 10, 31, 12).millisecondsSinceEpoch);
    server = FakeRelayServer();
    directory = FakeDirectory();
    alice = Device('alice', server, directory, clock);
    sweeper = ExpirySweeper(db: alice.db, clock: clock);
    await alice.connect('bob');
    await alice.connect('carol');
  });

  tearDown(() => alice.close());

  test('the timer applies only to messages sent after it was enabled', () async {
    final before = await alice.messages.sendText('bob', 'sent before the timer');
    await alice.messages.setTimer('bob', hour.inSeconds);
    final after = await alice.messages.sendText('bob', 'sent with the timer');

    final rows = {for (final m in await alice.messagesWith('bob')) m.id: m};
    expect(rows[before]!.expiresAt, isNull);
    expect(rows[after]!.expiresAt, clock.now + hour.inMilliseconds);
  });

  test('the sweep deletes exactly the expired messages and queues a relayed delete', () async {
    await alice.messages.setTimer('bob', hour.inSeconds);
    final mine = await alice.messages.sendText('bob', 'expires in one hour');
    final untimed = await alice.messages.sendText('carol', 'no timer here');

    clock.advance(const Duration(minutes: 30));
    final laterMine = await alice.messages.sendText('bob', 'sent 30 minutes later');

    // Nothing has expired yet.
    expect(await sweeper.sweep(), 0);

    // One hour after the first message: only that one is gone.
    clock.advance(const Duration(minutes: 30));
    expect(await sweeper.sweep(), 1);
    final bobIds = (await alice.messagesWith('bob')).map((m) => m.id).toSet();
    expect(bobIds.contains(mine), isFalse);
    expect(bobIds.contains(laterMine), isTrue);
    expect((await alice.messagesWith('carol')).map((m) => m.id), contains(untimed));

    // The deletion is relayed to the peer, end-to-end encrypted.
    await alice.messages.relayPendingDeletes();
    final deletes = [
      for (final e in await alice.outbox())
        if (e.type == 'delete') FakeCrypto.open(e.envelope),
    ];
    expect(deletes, hasLength(1));
    expect(deletes.single.to, 'bob');
    expect((deletes.single.payload as DeletePayload).ids, [mine]);

    // Thirty minutes more: the second timed message expires too.
    clock.advance(const Duration(minutes: 30));
    expect(await sweeper.sweep(), 1);
    expect((await alice.messagesWith('bob')).map((m) => m.id), isNot(contains(laterMine)));
  });

  test('expired messages are hidden even before the sweep runs', () async {
    await alice.messages.setTimer('bob', hour.inSeconds);
    await alice.messages.sendText('bob', 'short-lived');
    clock.advance(const Duration(hours: 2));

    final visible = await alice.db.watchMessages('bob', now: clock.nowMs).first;
    expect(visible.where((m) => m.kind == 'text'), isEmpty);
  });

  test('received timed messages expire relative to the moment they were sent', () async {
    final sentAt = clock.now - const Duration(minutes: 50).inMilliseconds;
    final payload = TextPayload(id: 'm-1', body: 'hi', sentAt: sentAt, ttlSeconds: hour.inSeconds);
    final env = await _incoming('bob', payload);
    await alice.messages.handleIncoming(env);

    final stored = (await alice.messagesWith('bob')).single;
    expect(stored.expiresAt, sentAt + hour.inMilliseconds);

    clock.advance(const Duration(minutes: 10));
    expect(await sweeper.sweep(), 1);
    expect(await alice.messagesWith('bob'), isEmpty);
  });

  test('free plan: a third timer chat is blocked', () async {
    await alice.connect('dave');
    await alice.messages.setTimer('bob', hour.inSeconds);
    await alice.messages.setTimer('carol', 86400);
    await expectLater(alice.messages.setTimer('dave', hour.inSeconds), throwsA(isA<TimerLimitReached>()));
    expect((await alice.db.chatById('dave'))!.timerSeconds, isNull);
    // Changing the duration of an existing timer chat is still allowed.
    await alice.messages.setTimer('bob', 5 * 3600);
    // Freeing a slot makes room again.
    await alice.messages.setTimer('carol', null);
    await alice.messages.setTimer('dave', hour.inSeconds);
  });
}

int _seq = 0;

/// Wraps a payload the way a peer's phone would send it.
Future<IncomingEnvelope> _incoming(String from, Payload payload) async {
  final crypto = FakeCrypto()..sessions.add('alice');
  final wire = await crypto.encrypt('alice', payload.encode());
  return IncomingEnvelope(
    id: 'relay-${_seq++}',
    senderId: from,
    type: payload.relayType,
    ciphertext: wire.encode(),
  );
}
