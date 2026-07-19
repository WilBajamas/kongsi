import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kongsi/core/config/app_config.dart';
import 'package:kongsi/core/di/core_providers.dart';
import 'package:kongsi/core/logger/app_logger.dart';
import 'package:kongsi/main.dart';

/// Shared startup for all flavors: one logger, three error nets, one runApp.
void bootstrap(AppConfig config) {
  final talker = createLogger();

  // Framework errors (build/layout/paint) arrive here.
  FlutterError.onError = (details) {
    talker.handle(details.exception, details.stack);
  };

  // Async errors with no local handler arrive here.
  PlatformDispatcher.instance.onError = (error, stack) {
    talker.handle(error, stack);
    return true;
  };

  runZonedGuarded(
    () {
      // Binding must init in the same zone as runApp, or Flutter asserts.
      WidgetsFlutterBinding.ensureInitialized();
      runApp(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(config),
            // Same instance the nets write to, so all logs share one stream.
            talkerProvider.overrideWithValue(talker),
          ],
          child: const MainApp(),
        ),
      );
    },
    talker.handle,
  );
}
