import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import '../widgets/private_text_field.dart';

/// Signs this phone in again with an e-mail code.
///
/// * Default: re-establishes a lost server session. Local chats, keys and
///   passwords are untouched.
/// * [takeOver]: the account moved to another phone; this registers fresh
///   keys here and cuts the other phone off (one phone per account).
class ReconnectScreen extends ConsumerStatefulWidget {
  const ReconnectScreen({super.key, this.takeOver = false});

  final bool takeOver;

  @override
  ConsumerState<ReconnectScreen> createState() => _ReconnectScreenState();
}

class _ReconnectScreenState extends ConsumerState<ReconnectScreen> {
  final _code = TextEditingController();
  bool _sent = false;
  bool _busy = false;
  String? _error;
  String? _email;

  @override
  void initState() {
    super.initState();
    unawaited(ref.read(servicesProvider).account.maskedEmail().then((value) {
      if (mounted) setState(() => _email = value);
    }));
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on Object catch (e) {
      if (mounted) setState(() => _error = describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() => _run(() async {
        await ref.read(servicesProvider).account.sendResetCode();
        setState(() => _sent = true);
      });

  Future<void> _verify() => _run(() async {
        final account = ref.read(servicesProvider).account;
        if (widget.takeOver) {
          await account.takeOverAccount(_code.text);
        } else {
          await account.reconnect(_code.text);
        }
        unawaited(ref.read(runtimeProvider).restart());
        if (mounted) Navigator.of(context).pop();
      });

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return Scaffold(
      appBar: AppBar(title: Text(widget.takeOver ? 'Use BVM on this phone' : 'Sign in again')),
      body: FormPage(
        children: [
          if (widget.takeOver) ...[
            const Text(
              'Your account is active on another phone. If you continue, this phone gets new '
              'encryption keys and the other phone stops sending and receiving messages. '
              'Your contacts will see that your security code changed.',
            ),
            const SizedBox(height: 12),
          ],
          Text('We will send a one-time code to ${_email ?? 'your e-mail address'}.'),
          const SizedBox(height: 16),
          if (!_sent)
            BusyButton(label: 'Send code', busy: _busy, onPressed: _send)
          else ...[
            PrivateTextField(
              controller: _code,
              label: 'Code',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 10,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            BusyButton(label: 'Verify', busy: _busy, onPressed: _verify),
          ],
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }
}
