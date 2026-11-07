import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/bootstrap.dart';
import 'presentation/app.dart';
import 'presentation/providers.dart';

Future<void> main() async {
  if (kReleaseMode) {
    // Release builds log nothing: silence debugPrint, and the zone below
    // swallows print() calls from any package.
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      final boot = await bootstrap();
      switch (boot) {
        case BootMisconfigured():
          runApp(const MisconfiguredApp());
        case BootFailed(:final reason):
          runApp(BootFailedApp(reason: reason));
        case BootReady(:final services, :final setupComplete):
          runApp(
            ProviderScope(
              overrides: [
                servicesProvider.overrideWithValue(services),
                setupCompleteProvider.overrideWithValue(setupComplete),
              ],
              child: const BvmApp(),
            ),
          );
      }
    },
    (error, stack) {
      if (kDebugMode) debugPrint('[bvm] uncaught ${error.runtimeType}');
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        if (!kReleaseMode) parent.print(zone, line);
      },
    ),
  );
}
