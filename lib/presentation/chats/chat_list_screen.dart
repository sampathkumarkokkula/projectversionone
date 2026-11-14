import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../domain/models.dart';
import '../chat/chat_screen.dart';
import '../providers.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import '../util/format.dart';
import '../widgets/avatar.dart';
import 'new_chat_screen.dart';
import 'reconnect_screen.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(chatSummariesProvider);
    final replaced = ref.watch(deviceReplacedProvider).value ?? false;
    final signedIn = ref.watch(servicesProvider).backend.userId != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            tooltip: 'Search messages',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New chat',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const NewChatScreen()),
        ),
        child: const Icon(Icons.edit_outlined),
      ),
      body: Column(
        children: [
          if (replaced)
            MaterialBanner(
              content: const Text(
                'Your account is now active on another phone. This phone no longer sends or '
                'receives messages; auto-delete still runs here.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const ReconnectScreen(takeOver: true)),
                  ),
                  child: const Text('Use BVM on this phone'),
                ),
              ],
            )
          else if (!signedIn)
            MaterialBanner(
              content: const Text('This phone is signed out of the server, so messages cannot be sent or received.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const ReconnectScreen()),
                  ),
                  child: const Text('Sign in again'),
                ),
              ],
            ),
          Expanded(
            child: summaries.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(child: Text('Could not load chats.')),
              data: (items) => items.isEmpty
                  ? const _EmptyChats()
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                      itemBuilder: (context, i) => _ChatTile(summary: items[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChats extends StatelessWidget {
  const _EmptyChats();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'No chats yet.\nTap the pencil to start a chat by username.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.summary});

  final ChatSummary summary;

  @override
  Widget build(BuildContext context) {
    final chat = summary.chat;
    final last = summary.lastMessage;
    final scheme = Theme.of(context).colorScheme;
    String preview;
    if (last == null) {
      preview = chat.timerSeconds != null ? 'Auto-delete is on' : 'No messages';
    } else if (last.kind == MessageKind.system.name) {
      preview = last.body;
    } else {
      final body = messagePreview(last);
      preview = last.fromMe ? 'You: $body' : body;
    }
    final label = chat.blocked
        ? 'Blocked'
        : !chat.accepted
            ? 'Request'
            : null;
    return ListTile(
      leading: AvatarCircle(ownerId: chat.peerId, name: chat.peerUsername),
      title: Row(
        children: [
          Flexible(child: Text(chat.peerUsername, maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (label != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: chat.blocked ? scheme.errorContainer : scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(label, style: Theme.of(context).textTheme.labelSmall),
            ),
          ],
        ],
      ),
      subtitle: Text(
        preview.replaceAll('\n', ' '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: last?.kind == MessageKind.system.name ? const TextStyle(fontStyle: FontStyle.italic) : null,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (last != null) Text(formatListTime(context, last.localAt), style: Theme.of(context).textTheme.labelSmall),
          if (chat.timerSeconds != null) Icon(Icons.timer_outlined, size: 16, color: scheme.primary),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ChatScreen(chatId: chat.peerId)),
      ),
    );
  }
}
