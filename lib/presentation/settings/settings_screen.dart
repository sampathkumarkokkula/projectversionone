import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/account_deletion.dart';
import '../../data/local/app_database.dart' show selfAvatarId;
import '../providers.dart';
import '../session_controller.dart';
import '../util/format.dart';
import '../widgets/avatar.dart';
import '../widgets/common.dart';
import 'blocked_users_screen.dart';
import 'password_screens.dart';
import 'privacy_policy_screen.dart';
import 'profile_actions.dart';

/// Settings never reveal whether a secondary password is set: the entry is
/// always present, always opens the same form, and shows no state.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = ref.watch(usernameProvider).value;
    final scheme = Theme.of(context).colorScheme;
    void open(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    final replaced = ref.watch(deviceReplacedProvider).value ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => editAvatar(context, ref),
              child: Stack(
                children: [
                  AvatarCircle(ownerId: selfAvatarId, name: username ?? '', radius: 48),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      child: const Icon(Icons.photo_camera_outlined, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Only people you chat with see your picture.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          ListTile(
            leading: const Icon(Icons.alternate_email),
            title: Text(username ?? ''),
            subtitle: const Text('Your username. Others find you only by this name.'),
            trailing: replaced ? null : const Icon(Icons.edit_outlined),
            onTap: replaced ? null : () => changeUsernameDialog(context, ref, username ?? ''),
          ),
          const Divider(),
          const _Header('Notifications'),
          const _NotificationsTile(),
          const Divider(),
          const _Header('Safety'),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Blocked users'),
            onTap: replaced ? null : () => open(const BlockedUsersScreen()),
          ),
          const Divider(),
          const _Header('Security'),
          ListTile(
            leading: const Icon(Icons.password),
            title: const Text('Change password'),
            onTap: () => open(const ChangePasswordScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.key_outlined),
            title: const Text('Secondary password'),
            subtitle: const Text('Set, change or remove'),
            onTap: () => open(const SecondaryPasswordScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Lock now'),
            onTap: () => ref.read(sessionProvider.notifier).lock(),
          ),
          const Divider(),
          const _Header('Privacy'),
          const _Fact(
            Icons.enhanced_encryption_outlined,
            'Messages and photos are end-to-end encrypted (Olm / Double Ratchet).',
          ),
          const _Fact(Icons.phone_android, 'Chat history is stored only on your phones, in an encrypted database.'),
          const _Fact(Icons.location_off_outlined, 'Photos are sent without location or camera details.'),
          const _Fact(Icons.screenshot_monitor_outlined, 'Screenshots and screen recording are blocked.'),
          const _Fact(Icons.visibility_off_outlined, 'No online status, no last seen, no contact upload.'),
          const _Fact(Icons.keyboard_outlined, 'Keyboards are asked not to learn what you type.'),
          const _Fact(Icons.backup_outlined, 'App data is excluded from cloud backups and device transfers.'),
          ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: const Text('Privacy policy'),
            onTap: () => open(const PrivacyPolicyScreen()),
          ),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: 'BVM',
            applicationVersion: '1.0.0',
            applicationLegalese: 'Open-source licenses of the components are listed below.',
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: scheme.error),
            title: Text('Delete my account', style: TextStyle(color: scheme.error)),
            onTap: () => _confirmDelete(context, ref),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'This removes your username, keys, block list and undelivered messages and photos from the '
          'server, and erases every chat, photo and your profile picture on this phone. Copies on '
          'other people\'s phones are not affected. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(dialogContext).colorScheme.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final navigator = Navigator.of(context);
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(canPop: false, child: Center(child: CircularProgressIndicator())),
    ));
    try {
      await deleteAccountEverywhere(ref.read(servicesProvider), ref.read(runtimeProvider));
      navigator.pop();
      ref.read(sessionProvider.notifier).markDeleted();
    } on Object catch (e) {
      navigator.pop();
      if (context.mounted) showSnack(context, describeError(e));
    }
  }
}

class _NotificationsTile extends ConsumerStatefulWidget {
  const _NotificationsTile();

  @override
  ConsumerState<_NotificationsTile> createState() => _NotificationsTileState();
}

class _NotificationsTileState extends ConsumerState<_NotificationsTile> {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final enabled = await ref.read(servicesProvider).notifications.enabled();
    if (mounted) setState(() => _enabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    return ListTile(
      leading: Icon(enabled == false ? Icons.notifications_off_outlined : Icons.notifications_outlined),
      title: Text(enabled == false ? 'Notifications are off' : 'New-message notifications'),
      subtitle: const Text(
        'They only say "New message": never who wrote or what. While BVM is closed they can take up to '
        '15 minutes unless push is set up.',
      ),
      isThreeLine: true,
      trailing: enabled == false
          ? TextButton(
              onPressed: () async {
                await ref.read(servicesProvider).notifications.requestPermission();
                await _refresh();
              },
              child: const Text('Turn on'),
            )
          : null,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge),
      );
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => ListTile(dense: true, leading: Icon(icon), title: Text(text));
}
