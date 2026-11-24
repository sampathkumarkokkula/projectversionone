import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/account_deletion.dart';
import '../../app/sign_out.dart';
import '../../core/env.dart';
import '../../data/local/app_database.dart' show selfAvatarId;
import '../providers.dart';
import '../session_controller.dart';
import '../util/format.dart';
import '../widgets/avatar.dart';
import '../widgets/common.dart';
import 'blocked_users_screen.dart';
import 'erase_chats_screen.dart';
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
    final displayName = ref.watch(displayNameProvider).value;
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
            leading: const Icon(Icons.badge_outlined),
            title: Text(displayName ?? 'Add your name'),
            subtitle: const Text('Shown to the people you chat with, instead of your username.'),
            trailing: replaced ? null : const Icon(Icons.edit_outlined),
            onTap: replaced ? null : () => changeDisplayNameDialog(context, ref, displayName ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.alternate_email),
            title: Text(username ?? ''),
            subtitle: const Text('Your username. Others find you only by this name.'),
            trailing: replaced ? null : const Icon(Icons.edit_outlined),
            onTap: replaced ? null : () => changeUsernameDialog(context, ref, username ?? ''),
          ),
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
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('Chats erased by secondary password'),
            subtitle: const Text('Choose which conversations it deletes'),
            onTap: () => open(const EraseChatsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Lock now'),
            onTap: () => ref.read(sessionProvider.notifier).lock(),
          ),
          const Divider(),
          const _Header('Privacy'),
          const _Fact(Icons.enhanced_encryption_outlined, 'Messages and photos are end-to-end encrypted.'),
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
          AboutListTile(
            icon: const Icon(Icons.info_outline),
            applicationName: 'BVM',
            applicationVersion: Env.appVersion.isEmpty ? 'development build' : Env.appVersion,
            applicationLegalese: [
              if (Env.sourceCodeUrl.isNotEmpty) 'Source code: ${Env.sourceCodeUrl}',
              'Open-source licenses of the components are listed below.',
            ].join('\n\n'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            subtitle: const Text('Use BVM with another account. Erases chats on this phone.'),
            onTap: () => _confirmSignOut(context, ref),
          ),
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

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your account stays. Your passwords, name, picture and contact list are saved (encrypted) '
          'so you get them back when you sign in again, here or on another phone.\n\n'
          'All chats and photos on this phone are erased: chat history is never stored on the '
          'server. Your contacts will see that your security code changed when you sign in again.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    if (!await _runSignOut(context, ref, force: false) && context.mounted) {
      final anyway = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Contact list not saved'),
          content: const Text(
            'BVM could not reach the server to save your contact list and settings. If you sign out '
            'now, you may have to set up passwords and find your contacts again.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Sign out anyway')),
          ],
        ),
      );
      if (anyway == true && context.mounted) await _runSignOut(context, ref, force: true);
    }
  }

  /// False when the backup could not be saved (nothing was erased).
  Future<bool> _runSignOut(BuildContext context, WidgetRef ref, {required bool force}) async {
    final navigator = Navigator.of(context);
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(canPop: false, child: Center(child: CircularProgressIndicator())),
    ));
    try {
      await signOutAndErase(ref.read(servicesProvider), ref.read(runtimeProvider), force: force);
      navigator.pop();
      ref.read(sessionProvider.notifier).markSignedOut();
      return true;
    } on BackupNotSavedException {
      navigator.pop();
      return false;
    } on Object catch (e) {
      navigator.pop();
      if (context.mounted) showSnack(context, describeError(e));
      return true;
    }
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
