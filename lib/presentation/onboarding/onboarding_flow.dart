import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/account_service.dart';
import '../../data/remote/supabase_backend.dart';
import '../providers.dart';
import '../session_controller.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import '../widgets/private_text_field.dart';
import 'password_form.dart';

enum _Step { welcome, email, code, profile, restore, passwords }

/// Registration: e-mail (OTP) -> username, name + phone -> passwords.
/// An existing account on a new phone types its app password instead, which
/// restores the passwords, profile and contacts from the encrypted backup.
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  _Step _step = _Step.welcome;
  bool _busy = false;
  String? _error;

  final _email = TextEditingController();
  final _code = TextEditingController();
  final _username = TextEditingController();
  final _displayName = TextEditingController();
  final _phone = TextEditingController();
  final _restorePassword = TextEditingController();

  MyProfile? _existing;

  AccountService get _account => ref.read(servicesProvider).account;

  @override
  void dispose() {
    _restorePassword.clear();
    for (final c in [_email, _code, _username, _displayName, _phone, _restorePassword]) {
      c.dispose();
    }
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

  void _go(_Step step) => setState(() {
        _step = step;
        _error = null;
      });

  Future<void> _sendCode() async {
    final email = AccountService.normalizeEmail(_email.text);
    if (!AccountService.emailPattern.hasMatch(email)) {
      setState(() => _error = 'Enter a valid e-mail address.');
      return;
    }
    await _run(() async {
      await _account.sendSignInCode(email);
      _code.clear();
      _go(_Step.code);
    });
  }

  Future<void> _verifyCode() async {
    final code = _code.text.trim();
    if (!RegExp(r'^\d{6,10}$').hasMatch(code)) {
      setState(() => _error = 'Enter the code from the e-mail.');
      return;
    }
    await _run(() async {
      _existing = await _account.verifySignInCode(_email.text, code);
      if (_existing == null) {
        _go(_Step.profile);
      } else {
        _go(_account.hasRemoteBackup ? _Step.restore : _Step.passwords);
      }
    });
  }

  Future<void> _checkProfile() async {
    final username = AccountService.normalizeUsername(_username.text);
    final phone = AccountService.normalizePhone(_phone.text);
    if (!AccountService.usernamePattern.hasMatch(username)) {
      setState(() => _error = 'Usernames have 3-24 characters: a-z, 0-9 and _.');
      return;
    }
    if (!AccountService.phonePattern.hasMatch(phone)) {
      setState(() => _error = 'Enter the phone number with country code, for example +441234567890.');
      return;
    }
    await _run(() async {
      if (!await _account.usernameAvailable(username)) {
        throw const UsernameTakenException();
      }
      _go(_Step.passwords);
    });
  }

  Future<void> _restore() async {
    final password = _restorePassword.text;
    final existing = _existing;
    if (password.isEmpty || existing == null) return;
    await _run(() async {
      final mode = await _account.restoreOnThisDevice(profile: existing, password: password);
      if (mode == null) {
        _restorePassword.clear();
        if (mounted) setState(() => _error = 'Wrong password.');
        return;
      }
      _restorePassword.clear();
      ref.read(sessionProvider.notifier).finishOnboarding(mode: mode);
    });
  }

  Future<void> _finish(String main, String? secondary) async {
    setState(() => _error = null);
    try {
      final existing = _existing;
      if (existing == null) {
        await _account.register(
          username: _username.text,
          phone: _phone.text,
          mainPassword: main,
          secondaryPassword: secondary,
          displayName: _displayName.text,
        );
      } else {
        await _account.continueOnThisDevice(
          profile: existing,
          mainPassword: main,
          secondaryPassword: secondary,
        );
      }
      ref.read(sessionProvider.notifier).finishOnboarding();
    } on UsernameTakenException catch (e) {
      if (mounted) {
        setState(() {
          _step = _Step.profile;
          _error = describeError(e);
        });
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = describeError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final error = _error;
    final children = switch (_step) {
      _Step.welcome => [
          Icon(Icons.lock_outline, size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text('BVM', textAlign: TextAlign.center, style: text.headlineMedium),
          const SizedBox(height: 12),
          const Text(
            'Private 1-to-1 messages. End-to-end encrypted. Your chat history is stored '
            'only on your phone, never on a server.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          BusyButton(label: 'Get started', onPressed: () => _go(_Step.email)),
        ],
      _Step.email => [
          Text('Your e-mail', style: text.headlineSmall),
          const SizedBox(height: 8),
          const Text('We send a one-time code to sign in. Other users never see your e-mail.'),
          const SizedBox(height: 20),
          PrivateTextField(
            controller: _email,
            label: 'E-mail',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofocus: true,
            onSubmitted: (_) => _sendCode(),
          ),
          const SizedBox(height: 20),
          BusyButton(label: 'Send code', busy: _busy, onPressed: _sendCode),
        ],
      _Step.code => [
          Text('Check your e-mail', style: text.headlineSmall),
          const SizedBox(height: 8),
          Text('Enter the code sent to ${AccountService.normalizeEmail(_email.text)}.'),
          const SizedBox(height: 20),
          PrivateTextField(
            controller: _code,
            label: 'Code',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 10,
            autofocus: true,
            onSubmitted: (_) => _verifyCode(),
          ),
          const SizedBox(height: 12),
          BusyButton(label: 'Verify', busy: _busy, onPressed: _verifyCode),
          TextButton(onPressed: _busy ? null : _sendCode, child: const Text('Send a new code')),
          TextButton(onPressed: _busy ? null : () => _go(_Step.email), child: const Text('Use another e-mail')),
        ],
      _Step.profile => [
          Text('Create your profile', style: text.headlineSmall),
          const SizedBox(height: 8),
          const Text('People find you by your username only. Your name is what they see in the chat.'),
          const SizedBox(height: 20),
          PrivateTextField(
            controller: _username,
            label: 'Username',
            helper: '3-24 characters: a-z, 0-9 and _. Used to find you.',
            maxLength: 24,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9_]')),
              LowerCaseFormatter(),
            ],
          ),
          const SizedBox(height: 12),
          PrivateTextField(
            controller: _displayName,
            label: 'Name (optional)',
            helper: 'Shown to the people you chat with. You can change it later.',
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          PrivateTextField(
            controller: _phone,
            label: 'Phone number',
            hint: '+441234567890',
            helper: 'Stored encrypted and never shown to anyone. Verification comes in a later version.',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          BusyButton(label: 'Continue', busy: _busy, onPressed: _checkProfile),
        ],
      _Step.restore => [
          Text('Welcome back, ${_existing!.username}', style: text.headlineSmall),
          const SizedBox(height: 8),
          const Text(
            'Enter your BVM password to restore your passwords, profile and contacts on this '
            'phone. Chat history never leaves a phone, so the chats start empty.',
          ),
          const SizedBox(height: 20),
          PrivateTextField(
            controller: _restorePassword,
            label: 'Password',
            obscure: true,
            autofocus: true,
            enabled: !_busy,
            onSubmitted: (_) => _restore(),
          ),
          const SizedBox(height: 16),
          BusyButton(label: 'Restore', busy: _busy, onPressed: _restore),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : () => _confirmStartFresh(context),
            child: const Text('Forgot your password? Start fresh'),
          ),
        ],
      _Step.passwords => [
          Text(_existing == null ? 'Protect the app' : 'Welcome back, ${_existing!.username}', style: text.headlineSmall),
          if (_existing != null) ...[
            const SizedBox(height: 8),
            const Text(
              'Choose your app passwords for this phone. Your contact list is not restored. '
              'Chat history never moves between phones.',
            ),
          ],
          const SizedBox(height: 20),
          PasswordForm(submitLabel: 'Finish', onSubmit: _finish),
        ],
    };
    return Scaffold(
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

  Future<void> _confirmStartFresh(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Start fresh?'),
        content: const Text(
          'You choose new passwords and start with an empty contact list. The saved contact list '
          'is replaced. Your account, username and blocked users stay.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Start fresh')),
        ],
      ),
    );
    if (ok == true) _go(_Step.passwords);
  }
}

/// Forces lower-case input (usernames are lower-case only).
class LowerCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toLowerCase());
}
