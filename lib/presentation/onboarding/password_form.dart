import 'package:flutter/material.dart';

import '../../domain/lock_service.dart';
import '../widgets/common.dart';
import '../widgets/private_text_field.dart';

typedef PasswordSubmit = Future<void> Function(String main, String? secondary);

/// Main password (required) + secondary password (optional), each typed
/// twice. Used at registration and after a "forgot password" reset.
class PasswordForm extends StatefulWidget {
  const PasswordForm({super.key, required this.submitLabel, required this.onSubmit});

  final String submitLabel;
  final PasswordSubmit onSubmit;

  @override
  State<PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<PasswordForm> {
  final _main = TextEditingController();
  final _mainAgain = TextEditingController();
  final _secondary = TextEditingController();
  final _secondaryAgain = TextEditingController();
  String? _mainError;
  String? _secondaryError;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_main, _mainAgain, _secondary, _secondaryAgain]) {
      c.clear();
      c.dispose();
    }
    super.dispose();
  }

  String? _check(String value, String again) {
    try {
      LockService.validate(value);
    } on PasswordPolicyException catch (e) {
      return e.message;
    }
    if (value != again) return 'The passwords do not match.';
    return null;
  }

  Future<void> _submit() async {
    final main = _main.text;
    final secondary = _secondary.text;
    final mainError = _check(main, _mainAgain.text);
    String? secondaryError;
    if (secondary.isNotEmpty || _secondaryAgain.text.isNotEmpty) {
      secondaryError = _check(secondary, _secondaryAgain.text);
      if (secondaryError == null && secondary == main) {
        secondaryError = 'The secondary password must differ from the main password.';
      }
    }
    setState(() {
      _mainError = mainError;
      _secondaryError = secondaryError;
    });
    if (mainError != null || secondaryError != null) return;
    setState(() => _busy = true);
    try {
      await widget.onSubmit(main, secondary.isEmpty ? null : secondary);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Main password', style: text.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Asked every time you open BVM. It never leaves this phone and cannot be recovered.',
          style: text.bodySmall,
        ),
        const SizedBox(height: 12),
        PrivateTextField(controller: _main, label: 'Main password', obscure: true, errorText: _mainError),
        const SizedBox(height: 12),
        PrivateTextField(controller: _mainAgain, label: 'Repeat main password', obscure: true),
        const SizedBox(height: 28),
        Text('Secondary password (optional)', style: text.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Unlocking with the secondary password looks exactly like a normal unlock, '
          'but it silently and permanently deletes every chat that has an auto-delete '
          'timer, on this phone and on the other person\'s phone. Use it if you are '
          'ever forced to unlock BVM. The app never shows whether one is set.',
          style: text.bodySmall,
        ),
        const SizedBox(height: 12),
        PrivateTextField(
          controller: _secondary,
          label: 'Secondary password',
          obscure: true,
          errorText: _secondaryError,
        ),
        const SizedBox(height: 12),
        PrivateTextField(controller: _secondaryAgain, label: 'Repeat secondary password', obscure: true),
        const SizedBox(height: 28),
        BusyButton(label: widget.submitLabel, busy: _busy, onPressed: _submit),
      ],
    );
  }
}
