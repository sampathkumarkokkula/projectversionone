import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../domain/timer_policy.dart';
import '../providers.dart';
import '../util/format.dart';
import '../widgets/common.dart';

/// Picks the auto-delete timer: Off, 1 hour, 5 hours, 1 day, 1 week.
Future<void> showTimerSheet(BuildContext context, WidgetRef ref, Chat chat) async {
  final choice = await showModalBottomSheet<TimerOption>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text('Auto-delete timer'),
            subtitle: Text(
              'Applies to messages sent from now on. The countdown starts when a message is sent. '
              'You both see when the timer changes.',
            ),
          ),
          for (final option in timerOptions)
            ListTile(
              title: Text(option.label),
              trailing: option.seconds == chat.timerSeconds ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(sheetContext).pop(option),
            ),
        ],
      ),
    ),
  );
  if (choice == null || choice.seconds == chat.timerSeconds) return;
  final services = ref.read(servicesProvider);
  try {
    // The change notice travels encrypted, so a session is needed first.
    await services.sessions.ensure(chat.peerId);
    await services.messages.setTimer(chat.peerId, choice.seconds);
    unawaited(ref.read(runtimeProvider).syncNow());
  } on TimerLimitReached {
    if (context.mounted) await showTimerUpsell(context);
  } on Object catch (e) {
    if (context.mounted) showSnack(context, describeError(e));
  }
}

/// Free plan: at most two chats with a timer at the same time.
Future<void> showTimerUpsell(BuildContext context) => showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.timer_outlined),
        title: const Text('Timer limit reached'),
        content: const Text(
          'The free version allows auto-delete on up to ${TimerPolicy.maxTimerChatsFree} chats at a time. '
          'Turn it off in another chat to use it here.\n\n'
          'BVM Plus, coming in a future version, will remove this limit.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('OK')),
        ],
      ),
    );
