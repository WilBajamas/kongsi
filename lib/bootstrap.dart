import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kongsi/app/app_bloc_observer.dart';
import 'package:kongsi/app/command_registrations.dart';
import 'package:kongsi/core/config/app_config.dart';
import 'package:kongsi/core/di/core_providers.dart';
import 'package:kongsi/core/logger/app_logger.dart';
import 'package:kongsi/core/sync/command_registry.dart';
import 'package:kongsi/core/sync/sync_event.dart';
import 'package:kongsi/features/groups/data/dev_seed.dart';
import 'package:kongsi/main.dart';

/// Shared startup for all flavors: one logger, four error nets, one runApp.
void bootstrap(AppConfig config) {
  final talker = createLogger();

  // Error Net 1: Framework errors (build/layout/paint) arrive here.
  FlutterError.onError = (details) {
    talker.handle(details.exception, details.stack, 'net 1 · FlutterError');
  };

  // Error Net 2: Async errors with no local handler arrive here.
  PlatformDispatcher.instance.onError = (error, stack) {
    talker.handle(error, stack, 'net 2 · PlatformDispatcher');
    return true;
  };

  // Error Net 3: Uncaught async errors, including Zone errors - fallback net
  unawaited(
    runZonedGuarded(
      () async {
        // Binding must init in the same zone as runApp, or Flutter asserts.
        WidgetsFlutterBinding.ensureInitialized();

        // Hand-built container so startup work and widgets share one graph.
        final container = ProviderContainer(
          overrides: [
            appConfigProvider.overrideWithValue(config),
            // Same instance the nets write to, so all logs share one stream.
            talkerProvider.overrideWithValue(talker),
            // Registry built from the app-layer catalog; core can't see it.
            commandRegistryProvider.overrideWithValue(
              CommandRegistry(commandRegistrations),
            ),
          ],
        );

        // Seed dev dummy data if in dev mode
        if (config.flavor == Flavor.dev) {
          await seedDevGroups(
            db: container.read(appDatabaseProvider),
            clock: container.read(clockProvider),
            uuid: container.read(uuidGeneratorProvider),
          );
        }

        // Error Net 4: Bloc errors
        // ! Note: This is a global observer, so it will catch all bloc errors.
        // ! This line is extremely dangerous and should always be used
        // ! here only. Because `Bloc.observer` is a mutable static state,
        // ! it can be mutated from anywhere in this project.
        // ! SHOULD ONLY BE USED HERE.
        Bloc.observer = AppBlocObserver(talker);

        runApp(
          UncontrolledProviderScope(
            container: container,
            child: const MainApp(),
          ),
        );

        // Kick-starts the sync only after runApp: the drain is optional
        // background work, so it must not delay the first frame and if
        // syncing ever throws an error, the app is already up.
        // Must stay below the Bloc.observer line: this read creates the
        // first Bloc.
        //
        // One drain per launch; connectivity-driven triggers come later.
        container.read(syncBlocProvider).add(const SyncRequested());
      },
      (error, stack) => talker.handle(error, stack, 'net 3 · zone'),
    ),
  );
}
