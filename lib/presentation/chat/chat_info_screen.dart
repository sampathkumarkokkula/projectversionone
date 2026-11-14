import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/safety_number.dart';
import '../../domain/timer_policy.dart';
import '../providers.dart';
import '../widgets/avatar.dart';
import 'safety_actions.dart';
import 'timer_sheet.dart';

final _ownSigningKeyProvider = FutureProvider.autoDispose<String>(
  (ref) => ref.watch(servicesProvider).crypto.signingKey(),
);

/// Contact details: picture, auto-delete setting, the safety number used to
/// verify end-to-end encryption in person, and the safety actions (block,
/// report spam, delete chat).
class ChatInfoScreen extends ConsumerWidget {
  const ChatInfoScreen({super.key, required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chat = ref.watch(chatProvider(chatId)).value;
    final ownKey = ref.watch(_ownSigningKeyProvider).value;
    final replaced = ref.watch(deviceReplacedProvider).value ?? false;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Chat info')),
      body: chat == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                Center(child: AvatarCircle(ownerId: chat.peerId, name: chat.peerUsername, radius: 48)),
                const SizedBox(height: 12),
                Text(chat.peerUsername, textAlign: TextAlign.center, style: text.headlineSmall),
                if (chat.blocked)
                  Text('Blocked', textAlign: TextAlign.center, style: TextStyle(color: scheme.error))
                else if (!chat.accepted)
                  const Text('Message request', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: const Text('Auto-delete timer'),
                  subtitle: Text(timerLabel(chat.timerSeconds)),
                  onTap: chat.blocked || replaced ? null : () => showTimerSheet(context, ref, chat),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Text('Safety number', style: text.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Compare this number with ${chat.peerUsername}, in person or on a call. '
                        'If it matches on both phones, nobody is intercepting your messages.',
                        style: text.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      if (ownKey != null)
                        SelectableText(
                          safetyNumber(ownKey, chat.peerSigningKey),
                          textAlign: TextAlign.center,
                          style: text.titleLarge?.copyWith(fontFamily: 'monospace', height: 1.6),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                const Divider(),
                if (!replaced) ...[
                  if (chat.blocked)
                    ListTile(
                      leading: const Icon(Icons.lock_open_outlined),
                      title: Text('Unblock ${chat.peerUsername}'),
                      onTap: () => unblockWithConfirm(context, ref, chat),
                    )
                  else
                    ListTile(
                      leading: Icon(Icons.block, color: scheme.error),
                      title: Text('Block ${chat.peerUsername}', style: TextStyle(color: scheme.error)),
                      onTap: () => blockWithConfirm(context, ref, chat),
                    ),
                  ListTile(
                    leading: Icon(Icons.report_outlined, color: scheme.error),
                    title: Text('Report spam', style: TextStyle(color: scheme.error)),
                    subtitle: const Text('Blocks them and deletes this chat'),
                    onTap: () => reportSpamWithConfirm(context, ref, chat),
                  ),
                ],
                ListTile(
                  leading: Icon(Icons.delete_outline, color: scheme.error),
                  title: Text('Delete chat', style: TextStyle(color: scheme.error)),
                  subtitle: const Text('From this phone only'),
                  onTap: () => deleteChatWithConfirm(context, ref, chat),
                ),
              ],
            ),
    );
  }
}
