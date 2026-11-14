import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../chat/chat_screen.dart';
import '../providers.dart';
import '../util/format.dart';
import '../widgets/avatar.dart';
import '../widgets/private_text_field.dart';

/// Searches text messages on this phone (never on a server). With [chatId]
/// the search is limited to that chat and picking a result returns its id to
/// the chat screen; otherwise it searches all chats and opens the result.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.chatId});

  final String? chatId;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<SearchHit> _hits = const [];
  String _searched = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => unawaited(_search(value.trim())));
  }

  Future<void> _search(String q) async {
    if (q.isEmpty) {
      setState(() {
        _hits = const [];
        _searched = '';
      });
      return;
    }
    final services = ref.read(servicesProvider);
    final hits = await services.db.searchMessages(q, chatId: widget.chatId, now: services.clock.nowMs());
    if (!mounted || _query.text.trim() != q) return;
    setState(() {
      _hits = hits;
      _searched = q;
    });
  }

  void _open(SearchHit hit) {
    if (widget.chatId != null) {
      Navigator.of(context).pop(hit.message.id);
      return;
    }
    unawaited(Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ChatScreen(chatId: hit.chat.peerId, focusMessageId: hit.message.id)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: PrivateTextField(
          controller: _query,
          autofocus: true,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          onSubmitted: (v) => unawaited(_search(v.trim())),
          decoration: InputDecoration(
            hintText: widget.chatId == null ? 'Search all messages' : 'Search in this chat',
            border: InputBorder.none,
          ),
        ),
      ),
      body: _searched.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Search runs only on this phone. Photos are not searched.', textAlign: TextAlign.center),
              ),
            )
          : _hits.isEmpty
              ? Center(child: Text('No messages contain "$_searched".'))
              : ListView.separated(
                  itemCount: _hits.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                  itemBuilder: (context, i) {
                    final hit = _hits[i];
                    return ListTile(
                      leading: AvatarCircle(ownerId: hit.chat.peerId, name: hit.chat.peerUsername),
                      title: Text(
                        hit.message.fromMe ? 'You → ${hit.chat.peerUsername}' : hit.chat.peerUsername,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: _Highlighted(text: hit.message.body, query: _searched, color: scheme.primary),
                      trailing: Text(formatListTime(context, hit.message.localAt),
                          style: Theme.of(context).textTheme.labelSmall),
                      onTap: () => _open(hit),
                    );
                  },
                ),
    );
  }
}

/// The message text with every occurrence of [query] in bold, trimmed so the
/// first match is visible.
class _Highlighted extends StatelessWidget {
  const _Highlighted({required this.text, required this.query, required this.color});

  final String text;
  final String query;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final flat = text.replaceAll('\n', ' ');
    final lower = flat.toLowerCase();
    final q = query.toLowerCase();
    var start = lower.indexOf(q);
    var shown = flat;
    if (start > 30) {
      shown = '…${flat.substring(start - 20)}';
    }
    final shownLower = shown.toLowerCase();
    final spans = <TextSpan>[];
    var i = 0;
    while (true) {
      start = shownLower.indexOf(q, i);
      if (start < 0 || q.isEmpty) {
        spans.add(TextSpan(text: shown.substring(i)));
        break;
      }
      if (start > i) spans.add(TextSpan(text: shown.substring(i, start)));
      spans.add(TextSpan(
        text: shown.substring(start, start + q.length),
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ));
      i = start + q.length;
    }
    return Text.rich(TextSpan(children: spans), maxLines: 2, overflow: TextOverflow.ellipsis);
  }
}
