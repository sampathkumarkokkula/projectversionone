import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../providers.dart';
import '../session_controller.dart';
import '../widgets/common.dart';
import '../widgets/private_text_field.dart';
import 'password_reset_screen.dart';

/// Asked on every launch and after more than 60 s in the background. Main
/// and secondary passwords go through the same code path and the same
/// screens; nothing here can tell them apart. No biometric unlock.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;
  Duration _lockout = Duration.zero;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshLockout());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _password.clear();
    _password.dispose();
    super.dispose();
  }

  Future<void> _refreshLockout() async {
    final remaining = await ref.read(servicesProvider).lock.remainingLockout();
    if (!mounted) return;
    setState(() => _lockout = remaining);
    _ticker?.cancel();
    if (remaining > Duration.zero) {
      _ticker = Timer(const Duration(seconds: 1), () => unawaited(_refreshLockout()));
    }
  }

  Future<void> _unlock() async {
    if (_busy || _lockout > Duration.zero) return;
    final password = _password.text;
    if (password.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    UnlockResult result;
    try {
      result = await ref.read(sessionProvider.notifier).unlock(password);
    } on Object {
      result = UnlockResult.invalid;
    }
    if (!mounted) return;
    if (result == UnlockResult.invalid) {
      _password.clear();
      setState(() {
        _busy = false;
        _error = 'Wrong password.';
      });
      await _refreshLockout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locked = _lockout > Duration.zero;
    return Scaffold(
      body: FormPage(
        children: [
          Icon(Icons.lock_outline, size: 56, color: scheme.primary),
          const SizedBox(height: 16),
          Text('BVM', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 32),
          PrivateTextField(
            controller: _password,
            label: 'Password',
            obscure: true,
            autofocus: true,
            enabled: !_busy && !locked,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _unlock(),
          ),
          const SizedBox(height: 16),
          BusyButton(label: 'Unlock', busy: _busy, onPressed: locked ? null : _unlock),
          const SizedBox(height: 12),
          if (locked)
            Text(
              'Too many attempts. Try again in ${_lockout.inSeconds + 1} s.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.error),
            )
          else if (_error != null)
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: scheme.error)),
          const SizedBox(height: 24),
          TextButton(
            onPressed: _busy
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const PasswordResetScreen()),
                    ),
            child: const Text('Forgot password?'),
          ),
        ],
      ),
    );
  }
}
