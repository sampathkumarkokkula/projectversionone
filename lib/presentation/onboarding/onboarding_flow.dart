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

enum _Step { welcome, email, code, profile, passwords }

/// Registration: e-mail (OTP) -> username + phone -> passwords. An existing
/// account signing in on a new phone skips the profile step.
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
  final _phone = TextEditingController();

  MyProfile? _existing;

  AccountService get _account => ref.read(servicesProvider).account;

  @override
  void dispose() {
    for (final c in [_email, _code, _username, _phone]) {
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
      _go(_existing == null ? _Step.profile : _Step.passwords);
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
          const Text('People find you by your username only.'),
          const SizedBox(height: 20),
          PrivateTextField(
            controller: _username,
            label: 'Username',
            helper: '3-24 characters: a-z, 0-9 and _',
            maxLength: 24,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9_]')),
              LowerCaseFormatter(),
            ],
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
      _Step.passwords => [
          Text(_existing == null ? 'Protect the app' : 'Welcome back, ${_existing!.username}', style: text.headlineSmall),
          if (_existing != null) ...[
            const SizedBox(height: 8),
            const Text(
              'Chat history never moves between phones, so this phone starts with an empty chat '
              'list. Your contacts will see that your security code changed.',
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
}

/// Forces lower-case input (usernames are lower-case only).
class LowerCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toLowerCase());
}
