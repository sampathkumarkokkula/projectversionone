import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/media/image_processor.dart';
import '../../domain/message_service.dart';
import '../../domain/models.dart';
import '../../domain/timer_policy.dart';
import '../providers.dart';
import '../search/search_screen.dart';
import '../util/format.dart';
import '../widgets/avatar.dart';
import '../widgets/common.dart';
import '../widgets/image_pick.dart';
import '../widgets/private_text_field.dart';
import 'chat_info_screen.dart';
import 'photo_viewer.dart';
import 'safety_actions.dart';
import 'timer_sheet.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.chatId, this.focusMessageId});

  final String chatId;

  /// Scroll to and highlight this message (from search).
  final String? focusMessageId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  final _focusKey = GlobalKey();
  late final AppLifecycleListener _lifecycle;
  bool _sending = false;
  Message? _replyTo;
  String? _highlightId;
  bool _focusPending = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _markRead);
    _highlightId = widget.focusMessageId;
    _focusPending = widget.focusMessageId != null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _composer.dispose();
    _scroll.dispose();
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
      await services.messages.sendText(widget.chatId, text, replyTo: _replyTo?.id);
      _composer.clear();
      setState(() => _replyTo = null);
      unawaited(ref.read(runtimeProvider).syncNow());
    } on Object catch (e) {
      if (mounted) showSnack(context, describeError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendPhoto() async {
    if (_sending) return;
    final services = ref.read(servicesProvider);
    try {
      final raw = await pickImage(context);
      if (raw == null || !mounted) return;
      setState(() => _sending = true);
      final photo = await ImageProcessor.preparePhoto(raw);
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          contentPadding: const EdgeInsets.all(12),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: Image.memory(photo.bytes, fit: BoxFit.contain),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Send')),
          ],
        ),
      );
      if (confirmed != true) return;
      await services.sessions.ensure(widget.chatId);
      await services.messages.sendImage(
        widget.chatId,
        photo.bytes,
        width: photo.width,
        height: photo.height,
        replyTo: _replyTo?.id,
      );
      if (mounted) setState(() => _replyTo = null);
      unawaited(ref.read(runtimeProvider).syncNow());
    } on Object catch (e) {
      if (mounted) showSnack(context, describeError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showActions(Message message, Chat chat, {required bool canSend}) async {
    if (message.kind == MessageKind.system.name) {
      final delete = await showModalBottomSheet<bool>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Delete for me'),
            onTap: () => Navigator.of(sheetContext).pop(true),
          ),
        ),
      );
      if (delete == true) await ref.read(servicesProvider).messages.deleteForMe(message.id);
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canSend)
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () => Navigator.of(sheetContext).pop('reply'),
              ),
            if (message.kind == MessageKind.text.name)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy text'),
                onTap: () => Navigator.of(sheetContext).pop('copy'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete for me'),
              onTap: () => Navigator.of(sheetContext).pop('delete_me'),
            ),
            if (message.fromMe && !chat.blocked)
              ListTile(
                leading: const Icon(Icons.delete_forever_outlined),
                title: const Text('Delete for everyone'),
                onTap: () => Navigator.of(sheetContext).pop('delete_all'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    final services = ref.read(servicesProvider);
    switch (action) {
      case 'reply':
        setState(() => _replyTo = message);
      case 'copy':
        await Clipboard.setData(ClipboardData(text: message.body));
        if (mounted) showSnack(context, 'Copied.');
      case 'delete_me':
        await services.messages.deleteForMe(message.id);
        if (_replyTo?.id == message.id) setState(() => _replyTo = null);
      case 'delete_all':
        await services.messages.deleteForEveryone(message.id);
        if (_replyTo?.id == message.id) setState(() => _replyTo = null);
        unawaited(ref.read(runtimeProvider).syncNow());
    }
  }

  Future<void> _openSearch() async {
    final messageId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => SearchScreen(chatId: widget.chatId)),
    );
    if (messageId == null || !mounted) return;
    setState(() {
      _highlightId = messageId;
      _focusPending = true;
    });
  }

  /// Scrolls the reversed list until the highlighted bubble is built, then
  /// centres it. Item heights vary, so this probes with growing estimates.
  void _scrollToFocus(int index, [int attempt = 0]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final focusContext = _focusKey.currentContext;
      if (focusContext != null) {
        unawaited(Scrollable.ensureVisible(focusContext, alignment: 0.5, duration: const Duration(milliseconds: 250)));
        Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _highlightId = null);
        });
        return;
      }
      if (attempt > 8 || !_scroll.hasClients) return;
      final estimate = index * 72.0 * (1 + attempt * 0.5);
      _scroll.jumpTo(min(estimate, _scroll.position.maxScrollExtent));
      _scrollToFocus(index, attempt + 1);
    });
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
    final blocked = chat?.blocked ?? false;
    final canSend = chat != null && !replaced && !blocked;
    final subtitle = chat == null
        ? null
        : blocked
            ? 'Blocked'
            : !chat.accepted
                ? 'Message request'
                : timer != null
                    ? 'Auto-delete: ${timerLabel(timer)}'
                    : null;

    final rows = messages.value;
    if (_focusPending && rows != null && _highlightId != null) {
      _focusPending = false;
      final index = rows.indexWhere((m) => m.id == _highlightId);
      if (index >= 0) _scrollToFocus(index);
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: chat == null
            ? null
            : InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => ChatInfoScreen(chatId: chat.peerId)),
                ),
                child: Row(
                  children: [
                    AvatarCircle(ownerId: chat.peerId, name: chat.peerUsername, radius: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(chat.peerUsername, maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (subtitle != null) Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        actions: [
          if (canSend)
            IconButton(
              tooltip: 'Auto-delete timer',
              icon: Icon(timer == null ? Icons.timer_off_outlined : Icons.timer_outlined),
              onPressed: () => showTimerSheet(context, ref, chat),
            ),
          IconButton(tooltip: 'Search in chat', icon: const Icon(Icons.search), onPressed: _openSearch),
        ],
      ),
      body: Column(
        children: [
          if (chat != null && blocked)
            MaterialBanner(
              content: Text('You blocked ${chat.peerUsername}. They cannot send you messages.'),
              actions: [
                TextButton(onPressed: () => unblockWithConfirm(context, ref, chat), child: const Text('Unblock')),
              ],
            )
          else if (chat != null && !chat.accepted)
            MaterialBanner(
              content: Text(
                '${chat.peerUsername} is not in your chats. They won\'t see that you read their '
                'messages or your profile picture until you accept.',
              ),
              actions: [
                TextButton(onPressed: () => reportSpamWithConfirm(context, ref, chat), child: const Text('Report spam')),
                TextButton(onPressed: () => blockWithConfirm(context, ref, chat), child: const Text('Block')),
                TextButton(
                  onPressed: () => ref.read(servicesProvider).messages.acceptChat(chat.peerId),
                  child: const Text('Accept'),
                ),
              ],
            ),
          Expanded(
            child: messages.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(child: Text('Could not load messages.')),
              data: (rows) {
                if (rows.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        timer == null
                            ? 'Messages and photos are end-to-end encrypted and stored only on your two phones.'
                            : 'New messages disappear ${timerLabel(timer)} after they are sent.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final byId = {for (final m in rows) m.id: m};
                return ListView.builder(
                  controller: _scroll,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final m = rows[i];
                    final highlighted = m.id == _highlightId;
                    return _MessageBubble(
                      key: highlighted ? _focusKey : ValueKey(m.id),
                      message: m,
                      peerName: chat?.peerUsername ?? '',
                      quoted: m.replyTo == null ? null : byId[m.replyTo],
                      hasQuote: m.replyTo != null,
                      highlighted: highlighted,
                      onLongPress: chat == null ? null : () => _showActions(m, chat, canSend: canSend),
                    );
                  },
                );
              },
            ),
          ),
          if (_replyTo != null && canSend)
            _ReplyPreview(
              message: _replyTo!,
              peerName: chat.peerUsername,
              onCancel: () => setState(() => _replyTo = null),
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
                : !canSend
                    ? const SizedBox(height: 8)
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: 'Send a photo',
                              onPressed: _sending ? null : _sendPhoto,
                              icon: const Icon(Icons.add_photo_alternate_outlined),
                            ),
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
                              icon: _sending
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.send),
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

/// Short text describing a message, for quotes and lists.
String messagePreview(Message m) => m.kind == MessageKind.image.name ? 'Photo' : m.body.replaceAll('\n', ' ');

class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({required this.message, required this.peerName, required this.onCancel});

  final Message message;
  final String peerName;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: scheme.primary, width: 3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${message.fromMe ? 'yourself' : peerName}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.primary),
                ),
                Text(messagePreview(message), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(tooltip: 'Cancel reply', icon: const Icon(Icons.close), onPressed: onCancel),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.message,
    required this.peerName,
    required this.quoted,
    required this.hasQuote,
    required this.highlighted,
    required this.onLongPress,
  });

  final Message message;
  final String peerName;

  /// The replied-to message, if it still exists on this phone.
  final Message? quoted;
  final bool hasQuote;
  final bool highlighted;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (message.kind == MessageKind.system.name) {
      return GestureDetector(
        onLongPress: onLongPress,
        child: Padding(
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
    final isImage = message.kind == MessageKind.image.name;
    final background = highlighted
        ? scheme.tertiaryContainer
        : mine
            ? scheme.primaryContainer
            : scheme.surfaceContainerHigh;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: GestureDetector(
          onLongPress: onLongPress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: EdgeInsets.fromLTRB(isImage ? 4 : 12, isImage ? 4 : 8, isImage ? 4 : 12, 6),
            decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasQuote) _Quote(quoted: quoted, peerName: peerName),
                if (isImage)
                  _PhotoThumbnail(messageId: message.id)
                else
                  Align(alignment: Alignment.centerLeft, child: Text(message.body)),
                const SizedBox(height: 2),
                Padding(
                  padding: EdgeInsets.only(right: isImage ? 6 : 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [for (final w in meta) Padding(padding: const EdgeInsets.only(left: 4), child: w)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Quote extends StatelessWidget {
  const _Quote({required this.quoted, required this.peerName});

  final Message? quoted;
  final String peerName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final q = quoted;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: scheme.primary, width: 3)),
      ),
      child: q == null
          ? Text('Message no longer available', style: TextStyle(fontStyle: FontStyle.italic, color: scheme.outline))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q.fromMe ? 'You' : peerName,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.primary),
                ),
                Text(messagePreview(q), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
    );
  }
}

class _PhotoThumbnail extends ConsumerWidget {
  const _PhotoThumbnail({required this.messageId});

  final String messageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(mediaProvider(messageId)).value;
    const width = 240.0;
    if (media == null) {
      return const SizedBox(width: width, height: 180, child: Center(child: Icon(Icons.image_outlined)));
    }
    final height = (width * media.height / max(media.width, 1)).clamp(80.0, 360.0);
    final cacheWidth = (width * MediaQuery.of(context).devicePixelRatio).round();
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => PhotoViewer(bytes: media.bytes)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(media.bytes, width: width, height: height, fit: BoxFit.cover, cacheWidth: cacheWidth),
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
