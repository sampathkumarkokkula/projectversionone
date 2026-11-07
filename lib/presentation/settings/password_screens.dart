import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/lock_service.dart';
import '../providers.dart';
import '../session_controller.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import '../widgets/private_text_field.dart';

/// Shared form: current password, new password typed twice.
class _PasswordChangeForm extends ConsumerStatefulWidget {
  const _PasswordChangeForm({
    required this.title,
    required this.explanation,
    required this.newLabel,
    required this.allowEmpty,
    required this.onSave,
  });

  final String title;
  final String explanation;
  final String newLabel;
  final bool allowEmpty;
  final Future<bool> Function(String current, String next) onSave;

  @override
  ConsumerState<_PasswordChangeForm> createState() => _PasswordChangeFormState();
}

class _PasswordChangeFormState extends ConsumerState<_PasswordChangeForm> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _again = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_current, _next, _again]) {
      c.clear();
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final next = _next.text;
    if (next != _again.text) {
      setState(() => _error = 'The new passwords do not match.');
      return;
    }
    if (next.isEmpty && !widget.allowEmpty) {
      setState(() => _error = 'Enter a new password.');
      return;
    }
    if (next.isNotEmpty) {
      try {
        LockService.validate(next);
      } on PasswordPolicyException catch (e) {
        setState(() => _error = e.message);
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = await widget.onSave(_current.text, next);
      if (!mounted) return;
      if (!ok) {
        setState(() => _error = 'The current password is wrong.');
        return;
      }
      showSnack(context, 'Saved.');
      Navigator.of(context).pop();
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
      appBar: AppBar(title: Text(widget.title)),
      body: FormPage(
        children: [
          Text(widget.explanation),
          const SizedBox(height: 20),
          PrivateTextField(controller: _current, label: 'Current password', obscure: true),
          const SizedBox(height: 12),
          PrivateTextField(controller: _next, label: widget.newLabel, obscure: true),
          const SizedBox(height: 12),
          PrivateTextField(controller: _again, label: 'Repeat ${widget.newLabel.toLowerCase()}', obscure: true),
          const SizedBox(height: 20),
          BusyButton(label: 'Save', busy: _busy, onPressed: _save),
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }
}

class ChangePasswordScreen extends ConsumerWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PasswordChangeForm(
      title: 'Change password',
      explanation: 'Enter your current password, then the new one.',
      newLabel: 'New password',
      allowEmpty: false,
      onSave: (current, next) => ref.read(servicesProvider).lock.changePassword(
            mode: ref.read(sessionProvider).mode,
            current: current,
            next: next,
          ),
    );
  }
}

/// Same form whether or not a secondary password exists.
class SecondaryPasswordScreen extends ConsumerWidget {
  const SecondaryPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PasswordChangeForm(
      title: 'Secondary password',
      explanation: 'Enter your current password, then the secondary password you want to use. '
          'Leave the new fields empty to remove it.',
      newLabel: 'Secondary password',
      allowEmpty: true,
      onSave: (current, next) => ref.read(servicesProvider).lock.setSecondary(
            mode: ref.read(sessionProvider).mode,
            current: current,
            next: next,
          ),
    );
  }
}
