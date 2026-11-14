import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/account_service.dart';
import '../../data/local/app_database.dart' show selfAvatarId;
import '../../data/media/image_processor.dart';
import '../onboarding/onboarding_flow.dart' show LowerCaseFormatter;
import '../providers.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import '../widgets/image_pick.dart';
import '../widgets/private_text_field.dart';

/// Change or remove the profile picture.
Future<void> editAvatar(BuildContext context, WidgetRef ref) async {
  final services = ref.read(servicesProvider);
  final hasAvatar = await services.db.avatarOf(selfAvatarId) != null;
  if (!context.mounted) return;
  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_outlined),
            title: Text(hasAvatar ? 'Change picture' : 'Add a picture'),
            onTap: () => Navigator.of(sheetContext).pop('change'),
          ),
          if (hasAvatar)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove picture'),
              onTap: () => Navigator.of(sheetContext).pop('remove'),
            ),
        ],
      ),
    ),
  );
  if (action == null || !context.mounted) return;
  try {
    if (action == 'remove') {
      await services.account.removeAvatar();
    } else {
      final raw = await pickImage(context);
      if (raw == null) return;
      final avatar = await ImageProcessor.prepareAvatar(raw);
      await services.account.setAvatar(avatar.bytes);
    }
    unawaited(ref.read(runtimeProvider).syncNow());
  } on Object catch (e) {
    if (context.mounted) showSnack(context, describeError(e));
  }
}

Future<void> changeUsernameDialog(BuildContext context, WidgetRef ref, String current) =>
    showDialog<void>(context: context, builder: (_) => _UsernameDialog(current: current));

class _UsernameDialog extends ConsumerStatefulWidget {
  const _UsernameDialog({required this.current});

  final String current;

  @override
  ConsumerState<_UsernameDialog> createState() => _UsernameDialogState();
}

class _UsernameDialogState extends ConsumerState<_UsernameDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.current);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = AccountService.normalizeUsername(_name.text);
    if (!AccountService.usernamePattern.hasMatch(name)) {
      setState(() => _error = '3-24 characters: a-z, 0-9 and _.');
      return;
    }
    if (name == widget.current) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(servicesProvider).account.changeUsername(name);
      unawaited(ref.read(runtimeProvider).syncNow());
      if (!mounted) return;
      Navigator.of(context).pop();
      showSnack(context, 'Your username is now $name.');
    } on Object catch (e) {
      if (mounted) setState(() => _error = describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change username'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'People you chat with see the new name. Your old name becomes free for others. '
            'You can change it once every 24 hours.',
          ),
          const SizedBox(height: 12),
          PrivateTextField(
            controller: _name,
            label: 'Username',
            autofocus: true,
            maxLength: 24,
            errorText: _error,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9_]')),
              LowerCaseFormatter(),
            ],
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _busy ? null : _save, child: const Text('Save')),
      ],
    );
  }
}
