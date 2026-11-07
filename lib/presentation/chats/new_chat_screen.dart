import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/account_service.dart';
import '../chat/chat_screen.dart';
import '../onboarding/onboarding_flow.dart' show LowerCaseFormatter;
import '../providers.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import '../widgets/private_text_field.dart';

/// Start a chat by exact username. No contact list is ever read or uploaded.
class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  final _username = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final name = AccountService.normalizeUsername(_username.text);
    if (!AccountService.usernamePattern.hasMatch(name)) {
      setState(() => _error = 'Usernames have 3-24 characters: a-z, 0-9 and _.');
      return;
    }
    if (ref.read(deviceReplacedProvider).value ?? false) {
      setState(() => _error = 'Your account is active on another phone.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final services = ref.read(servicesProvider);
    try {
      final peer = await services.sessions.startChat(name, selfId: services.backend.userId);
      if (peer == null) {
        setState(() => _error = 'No one has that username.');
        return;
      }
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => ChatScreen(chatId: peer.userId)),
      );
    } on Object catch (e) {
      if (mounted) setState(() => _error = describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return Scaffold(
      appBar: AppBar(title: const Text('New chat')),
      body: FormPage(
        children: [
          const Text('Enter the exact username of the person you want to message.'),
          const SizedBox(height: 16),
          PrivateTextField(
            controller: _username,
            label: 'Username',
            autofocus: true,
            maxLength: 24,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9_]')),
              LowerCaseFormatter(),
            ],
            onSubmitted: (_) => _start(),
          ),
          const SizedBox(height: 16),
          BusyButton(label: 'Start chat', busy: _busy, onPressed: _start),
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }
}
