import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/supabase_backend.dart';
import '../providers.dart';
import '../util/format.dart';
import '../widgets/common.dart';

/// The account's block list as the server enforces it (it also survives
/// moving to a new phone).
class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  List<BlockedUser>? _users;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final users = await ref.read(servicesProvider).backend.myBlocks();
      if (mounted) {
        setState(() {
          _users = users;
          _error = null;
        });
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = describeError(e));
    }
  }

  Future<void> _unblock(BlockedUser user) async {
    try {
      await ref.read(servicesProvider).chatActions.unblock(user.userId);
      await _load();
    } on Object catch (e) {
      if (mounted) showSnack(context, describeError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = _users;
    final error = _error;
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked users')),
      body: error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(error, textAlign: TextAlign.center)))
          : users == null
              ? const Center(child: CircularProgressIndicator())
              : users.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Nobody is blocked. Block someone from their chat, or report spam from a message request.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView(
                      children: [
                        for (final user in users)
                          ListTile(
                            leading: const Icon(Icons.block),
                            title: Text(user.username ?? 'Deleted account'),
                            trailing: TextButton(onPressed: () => _unblock(user), child: const Text('Unblock')),
                          ),
                      ],
                    ),
    );
  }
}
