import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// Round profile picture, or the first letter of [name] when there is none.
class AvatarCircle extends ConsumerWidget {
  const AvatarCircle({super.key, required this.ownerId, required this.name, this.radius = 20});

  /// A peer's user id, or `selfAvatarId`.
  final String ownerId;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final bytes = ref.watch(avatarProvider(ownerId)).value;
    final cache = (radius * 2 * MediaQuery.of(context).devicePixelRatio).round();
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      foregroundImage: bytes == null ? null : ResizeImage(MemoryImage(bytes), width: cache, height: cache),
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: TextStyle(fontSize: radius * 0.8),
      ),
    );
  }
}
