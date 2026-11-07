import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/safety_number.dart';
import '../../domain/timer_policy.dart';
import '../providers.dart';

final _ownSigningKeyProvider = FutureProvider.autoDispose<String>(
  (ref) => ref.watch(servicesProvider).crypto.signingKey(),
);

/// Contact details: auto-delete setting and the safety number used to verify
/// end-to-end encryption in person.
class ChatInfoScreen extends ConsumerWidget {
  const ChatInfoScreen({super.key, required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chat = ref.watch(chatProvider(chatId)).value;
    final ownKey = ref.watch(_ownSigningKeyProvider).value;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(chat?.peerUsername ?? 'Chat info')),
      body: chat == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: const Text('Auto-delete timer'),
                  subtitle: Text(timerLabel(chat.timerSeconds)),
                ),
                const Divider(),
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
              ],
            ),
    );
  }
}
