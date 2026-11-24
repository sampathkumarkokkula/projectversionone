import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../providers.dart';
import '../session_controller.dart';
import '../widgets/avatar.dart';

/// Which chats the secondary password erases. Looks and behaves the same in
/// every session; see WipeService for what a secondary-password session sees.
class EraseChatsScreen extends ConsumerStatefulWidget {
  const EraseChatsScreen({super.key});

  @override
  ConsumerState<EraseChatsScreen> createState() => _EraseChatsScreenState();
}

class _EraseChatsScreenState extends ConsumerState<EraseChatsScreen> {
  Set<String>? _selected;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final selected = await ref.read(servicesProvider).wipe.selectedChats(ref.read(sessionProvider).mode);
    if (mounted) setState(() => _selected = selected);
  }

  Future<void> _toggle(String peerId, bool selected) async {
    setState(() => selected ? _selected!.add(peerId) : _selected!.remove(peerId));
    await ref
        .read(servicesProvider)
        .wipe
        .setSelected(peerId, selected: selected, mode: ref.read(sessionProvider).mode);
    // The selection is part of the encrypted account backup.
    unawaited(ref.read(runtimeProvider).syncNow());
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final chats = ref.watch(chatSummariesProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Chats erased by secondary password')),
      body: selected == null || chats == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'When BVM is unlocked with the secondary password, every message and photo of the '
                    'chats selected here is deleted from this phone and from the other person\'s phone. '
                    'The chats stay in the list, empty. Other chats are not touched.',
                  ),
                ),
                if (chats.isEmpty)
                  const Padding(padding: EdgeInsets.all(16), child: Text('No chats yet.')),
                for (final summary in chats)
                  CheckboxListTile(
                    secondary: AvatarCircle(ownerId: summary.chat.peerId, name: summary.chat.name),
                    title: Text(summary.chat.name),
                    subtitle: Text('@${summary.chat.peerUsername}'),
                    value: selected.contains(summary.chat.peerId),
                    onChanged: (v) => _toggle(summary.chat.peerId, v ?? false),
                  ),
              ],
            ),
    );
  }
}
