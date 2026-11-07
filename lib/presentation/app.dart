import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chats/chat_list_screen.dart';
import 'lock/lock_screen.dart';
import 'onboarding/onboarding_flow.dart';
import 'providers.dart';
import 'session_controller.dart';
import 'theme.dart';
import 'widgets/common.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class BvmApp extends ConsumerStatefulWidget {
  const BvmApp({super.key});

  @override
  ConsumerState<BvmApp> createState() => _BvmAppState();
}

class _BvmAppState extends ConsumerState<BvmApp> {
  late final AppLifecycleListener _lifecycle;
  bool _shielded = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onInactive: () => setState(() => _shielded = true),
      onResume: () => setState(() => _shielded = false),
      onHide: () {
        ref.read(sessionProvider.notifier).appHidden();
        ref.read(runtimeProvider).onBackground();
      },
      onShow: () {
        ref.read(sessionProvider.notifier).appShown();
        ref.read(runtimeProvider).onForeground();
      },
    );
    if (ref.read(setupCompleteProvider)) {
      // Runs while locked too, so wipe commands and expiries apply at once.
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(ref.read(runtimeProvider).start()));
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionProvider, (previous, next) {
      if (previous?.phase != next.phase) {
        // Leaving the unlocked state: drop every screen above the root so
        // nothing stays reachable behind the lock screen.
        rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    });
    return MaterialApp(
      title: 'BVM',
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: const _RootGate(),
      builder: (context, child) => Stack(
        children: [
          ?child,
          if (_shielded) const PrivacyShield(),
        ],
      ),
    );
  }
}

class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(sessionProvider.select((s) => s.phase));
    return switch (phase) {
      AppPhase.onboarding => const OnboardingFlow(),
      AppPhase.locked => const LockScreen(),
      AppPhase.unlocked => const ChatListScreen(),
      AppPhase.deleted => const _AccountDeletedScreen(),
    };
  }
}

class _AccountDeletedScreen extends StatelessWidget {
  const _AccountDeletedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FormPage(
        children: [
          const Icon(Icons.check_circle_outline, size: 56),
          const SizedBox(height: 16),
          const Text(
            'Your account was deleted from the server and all data was erased from this phone.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          BusyButton(label: 'Close BVM', onPressed: () => SystemNavigator.pop()),
        ],
      ),
    );
  }
}

/// Shown when the build has no backend configuration.
class MisconfiguredApp extends StatelessWidget {
  const MisconfiguredApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      home: const Scaffold(
        body: FormPage(
          children: [
            Icon(Icons.build_circle_outlined, size: 56),
            SizedBox(height: 16),
            Text(
              'This build of BVM has no server configuration.\n\n'
              'Create a free Supabase project, put its URL and publishable key into .env '
              '(see .env.example) and rebuild with scripts/build-apk.ps1.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when start-up failed (for example the secure storage is unavailable).
class BootFailedApp extends StatelessWidget {
  const BootFailedApp({super.key, required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      home: Scaffold(
        body: FormPage(
          children: [
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: 16),
            Text(
              'BVM could not start ($reason). Restart the app. If this keeps happening, '
              'reinstalling resets it (local chats are lost).',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
