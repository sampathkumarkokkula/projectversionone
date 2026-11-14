import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../providers.dart';
import '../util/format.dart';
import '../widgets/common.dart';

Future<bool> _confirm(BuildContext context, String title, String body, String action, {bool danger = false}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
        FilledButton(
          style: danger ? FilledButton.styleFrom(backgroundColor: Theme.of(dialogContext).colorScheme.error) : null,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(action),
        ),
      ],
    ),
  );
  return result == true;
}

Future<void> blockWithConfirm(BuildContext context, WidgetRef ref, Chat chat) async {
  final ok = await _confirm(
    context,
    'Block ${chat.peerUsername}?',
    'They will not be able to send you messages or photos, and won\'t be told that you blocked them. '
        'The chat stays on your phone.',
    'Block',
    danger: true,
  );
  if (!ok || !context.mounted) return;
  try {
    await ref.read(servicesProvider).chatActions.block(chat.peerId);
  } on Object catch (e) {
    if (context.mounted) showSnack(context, describeError(e));
  }
}

Future<void> unblockWithConfirm(BuildContext context, WidgetRef ref, Chat chat) async {
  final ok = await _confirm(context, 'Unblock ${chat.peerUsername}?', 'They can send you messages again.', 'Unblock');
  if (!ok || !context.mounted) return;
  try {
    await ref.read(servicesProvider).chatActions.unblock(chat.peerId);
  } on Object catch (e) {
    if (context.mounted) showSnack(context, describeError(e));
  }
}

/// Report + block + delete the chat, then leave the chat screen.
Future<void> reportSpamWithConfirm(BuildContext context, WidgetRef ref, Chat chat) async {
  final ok = await _confirm(
    context,
    'Report ${chat.peerUsername} as spam?',
    'They will be blocked and this chat deleted from your phone. Your report contains no messages '
        '(they stay end-to-end encrypted). Accounts reported by several people are suspended and '
        'their e-mail address is banned.',
    'Report and block',
    danger: true,
  );
  if (!ok || !context.mounted) return;
  final navigator = Navigator.of(context);
  try {
    await ref.read(servicesProvider).chatActions.reportSpam(chat.peerId);
    navigator.popUntil((route) => route.isFirst);
  } on Object catch (e) {
    if (context.mounted) showSnack(context, describeError(e));
  }
}

Future<void> deleteChatWithConfirm(BuildContext context, WidgetRef ref, Chat chat) async {
  final ok = await _confirm(
    context,
    'Delete this chat?',
    'All messages and photos with ${chat.peerUsername} are deleted from this phone. Their phone is not affected.',
    'Delete',
    danger: true,
  );
  if (!ok || !context.mounted) return;
  final navigator = Navigator.of(context);
  await ref.read(servicesProvider).chatActions.deleteChat(chat.peerId);
  navigator.popUntil((route) => route.isFirst);
}
