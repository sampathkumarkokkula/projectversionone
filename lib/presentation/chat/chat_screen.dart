import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../domain/message_service.dart';
import '../../domain/models.dart';
import '../../domain/timer_policy.dart';
import '../providers.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import '../widgets/private_text_field.dart';
import 'chat_info_screen.dart';
import 'timer_sheet.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _composer = TextEditingController();
  late final AppLifecycleListener _lifecycle;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _markRead);
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _composer.dispose();
    super.dispose();
  }

  /// Read receipts only while the chat is actually on screen.
  void _markRead() {
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) return;
    final services = ref.read(servicesProvider);
    unawaited(() async {
      try {
        await services.messages.markRead(widget.chatId);
        unawaited(ref.read(runtimeProvider).syncNow());
      } on Object {
        // Retried the next time messages change.
      }
    }());
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _sending) return;
    if (text.length > MessageService.maxBodyLength) {
      showSnack(context, 'Messages can have at most ${MessageService.maxBodyLength} characters.');
      return;
    }
    setState(() => _sending = true);
    final services = ref.read(servicesProvider);
    try {
      // Needs the network only when no session exists yet (for example after
      // this phone got new keys); afterwards sending works offline.
      await services.sessions.ensure(widget.chatId);
      await services.messages.sendText(widget.chatId, text);
      _composer.clear();
      unawaited(ref.read(runtimeProvider).syncNow());
    } on Object catch (e) {
      if (mounted) showSnack(context, describeError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider(widget.chatId)).value;
    final messages = ref.watch(messagesProvider(widget.chatId));
    final replaced = ref.watch(deviceReplacedProvider).value ?? false;
    ref.listen(messagesProvider(widget.chatId), (previous, next) {
      final rows = next.value;
      if (rows != null && rows.any((m) => !m.fromMe && m.status == MessageStatus.received.name)) {
        _markRead();
      }
    });
    final timer = chat?.timerSeconds;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(chat?.peerUsername ?? ''),
            if (timer != null)
              Text('Auto-delete: ${timerLabel(timer)}', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        actions: [
          if (chat != null && !replaced)
            IconButton(
              tooltip: 'Auto-delete timer',
              icon: Icon(timer == null ? Icons.timer_off_outlined : Icons.timer_outlined),
              onPressed: () => showTimerSheet(context, ref, chat),
            ),
          if (chat != null)
            IconButton(
              tooltip: 'Chat info',
              icon: const Icon(Icons.info_outline),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => ChatInfoScreen(chatId: chat.peerId)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(child: Text('Could not load messages.')),
              data: (rows) => rows.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          timer == null
                              ? 'Messages are end-to-end encrypted and stored only on your two phones.'
                              : 'New messages disappear ${timerLabel(timer)} after they are sent.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: rows.length,
                      itemBuilder: (context, i) => _MessageBubble(message: rows[i]),
                    ),
            ),
          ),
          SafeArea(
            top: false,
            child: replaced
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Your account is active on another phone, so this phone cannot send messages.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: PrivateTextField(
                            controller: _composer,
                            minLines: 1,
                            maxLines: 5,
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Message',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton.filled(
                          tooltip: 'Send',
                          onPressed: _sending ? null : _send,
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (message.kind == MessageKind.system.name) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(message.body, textAlign: TextAlign.center, style: text.labelMedium),
          ),
        ),
      );
    }
    final mine = message.fromMe;
    final status = parseStatus(message.status);
    final meta = <Widget>[
      if (message.expiresAt != null) Icon(Icons.timer_outlined, size: 12, color: scheme.outline),
      Text(formatClock(context, message.sentAt), style: text.labelSmall?.copyWith(color: scheme.outline)),
      if (mine) _StatusIcon(status: status),
    ];
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          decoration: BoxDecoration(
            color: mine ? scheme.primaryContainer : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Align(alignment: Alignment.centerLeft, child: Text(message.body)),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [for (final w in meta) Padding(padding: const EdgeInsets.only(left: 4), child: w)],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final MessageStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (IconData icon, Color color, String label) = switch (status) {
      MessageStatus.pending => (Icons.schedule, scheme.outline, 'Waiting to send'),
      MessageStatus.sent => (Icons.check, scheme.outline, 'Sent'),
      MessageStatus.delivered => (Icons.done_all, scheme.outline, 'Delivered'),
      MessageStatus.read => (Icons.done_all, scheme.primary, 'Read'),
      MessageStatus.failed => (Icons.error_outline, scheme.error, 'Not delivered'),
      MessageStatus.received => (Icons.check, scheme.outline, 'Received'),
    };
    return Semantics(label: label, child: Icon(icon, size: 14, color: color));
  }
}
