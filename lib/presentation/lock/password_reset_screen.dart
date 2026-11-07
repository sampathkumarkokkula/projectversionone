import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/account_service.dart';
import '../onboarding/password_form.dart';
import '../providers.dart';
import '../session_controller.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import '../widgets/private_text_field.dart';

enum _ResetStep { confirm, sendCode, newPasswords }

/// "Forgot password": first deletes every timer-enabled chat on this phone
/// (so a reset can never bypass the secondary password), then verifies the
/// account e-mail with a one-time code and sets new passwords.
class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  _ResetStep _step = _ResetStep.confirm;
  bool _busy = false;
  String? _error;
  String? _maskedEmail;
  final _code = TextEditingController();

  AccountService get _account => ref.read(servicesProvider).account;

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

  Future<void> _confirmWipe() => _run(() async {
        // Irreversible, and done before any reset step.
        await _account.beginPasswordReset();
        _maskedEmail = await _account.maskedEmail();
        setState(() => _step = _ResetStep.sendCode);
      });

  Future<void> _sendCode() => _run(() async {
        await _account.sendResetCode();
        setState(() => _step = _ResetStep.newPasswords);
      });

  Future<void> _complete(String main, String? secondary) async {
    final code = _code.text.trim();
    if (!RegExp(r'^\d{6,10}$').hasMatch(code)) {
      setState(() => _error = 'Enter the code from the e-mail.');
      return;
    }
    setState(() => _error = null);
    try {
      await _account.completePasswordReset(code: code, mainPassword: main, secondaryPassword: secondary);
      if (!mounted) return;
      // Switching from locked to unlocked pops every route above the root
      // (see BvmApp), which closes this screen. Popping here as well would
      // remove the root route and leave a blank screen.
      ref.read(sessionProvider.notifier).finishPasswordReset();
    } on Object catch (e) {
      if (mounted) setState(() => _error = describeError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final error = _error;
    final children = switch (_step) {
      _ResetStep.confirm => [
          Text('Reset your password?', style: text.headlineSmall),
          const SizedBox(height: 12),
          const Text(
            'To protect you, every chat that has an auto-delete timer is permanently deleted '
            'from this phone before the reset. Chats without a timer are kept. This cannot be undone.',
          ),
          const SizedBox(height: 24),
          BusyButton(label: 'Delete timer chats and continue', busy: _busy, onPressed: _confirmWipe),
          TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ],
      _ResetStep.sendCode => [
          Text('Verify your e-mail', style: text.headlineSmall),
          const SizedBox(height: 12),
          Text('We will send a one-time code to ${_maskedEmail ?? 'your e-mail address'}.'),
          const SizedBox(height: 24),
          BusyButton(label: 'Send code', busy: _busy, onPressed: _sendCode),
        ],
      _ResetStep.newPasswords => [
          Text('Choose new passwords', style: text.headlineSmall),
          const SizedBox(height: 12),
          PrivateTextField(
            controller: _code,
            label: 'Code from the e-mail',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 10,
          ),
          TextButton(onPressed: _busy ? null : _sendCode, child: const Text('Send a new code')),
          const SizedBox(height: 12),
          PasswordForm(submitLabel: 'Save and unlock', onSubmit: _complete),
        ],
    };
    // Leaving after the wipe simply returns to the lock screen; the timer
    // chats are already gone, so there is nothing to bypass.
    return Scaffold(
      appBar: AppBar(),
      body: FormPage(
        children: [
          ...children,
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }
}
