import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kongsi/core/config/app_config.dart';
import 'package:kongsi/core/connectivity/connectivity_monitor.dart';
import 'package:kongsi/core/connectivity/stub_connectivity_monitor.dart';
import 'package:kongsi/core/database/app_database.dart';
import 'package:kongsi/core/logger/app_logger.dart';
import 'package:kongsi/core/network/auth_token_provider.dart';
import 'package:kongsi/core/network/dio_client.dart';
import 'package:kongsi/core/network/no_auth_token_provider.dart';
import 'package:kongsi/core/sync/command_registry.dart';
import 'package:kongsi/core/sync/command_sender.dart';
import 'package:kongsi/core/sync/drift_outbox_repository.dart';
import 'package:kongsi/core/sync/outbox_repository.dart';
import 'package:kongsi/core/sync/supabase_command_sender.dart';
import 'package:kongsi/core/sync/sync_bloc.dart';
import 'package:kongsi/core/system/clock.dart';
import 'package:kongsi/core/system/uuid_generator.dart';
import 'package:talker_flutter/talker_flutter.dart';

final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('override at ProviderScope'),
);

final talkerProvider = Provider<Talker>((ref) => createLogger());

final clockProvider = Provider<Clock>((ref) => SystemClock());

final uuidGeneratorProvider = Provider<UuidGenerator>(
  (ref) => UuidV4Generator(),
);

final authTokenProvider = Provider<AuthTokenProvider>(
  (ref) => const NoAuthTokenProvider(),
);

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close); // close the DB when the scope tears down
  return db;
});

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  return createDioClient(
    baseUrl: config.supabaseUrl,
    talker: ref.watch(talkerProvider),
    tokenProvider: ref.watch(authTokenProvider),
  );
});

// Built from the app-layer catalog, which core cannot import.
final commandRegistryProvider = Provider<CommandRegistry>(
  (ref) => throw UnimplementedError('override at bootstrap'),
);

final outboxRepositoryProvider = Provider<OutboxRepository>(
  (ref) => DriftOutboxRepository(ref.watch(appDatabaseProvider)),
);

// One swap seam for the whole drain: SyncBloc pushes through whatever this
// returns, so trading backends is a one-line change here. To watch the queue
// without hitting Supabase, swap the body for:
//   return LoggingCommandSender(ref.watch(talkerProvider));
final commandSenderProvider = Provider<CommandSender>((ref) {
  final config = ref.watch(appConfigProvider);
  return SupabaseCommandSender(
    dio: ref.watch(dioProvider),
    anonKey: config.supabaseAnonKey,
  );
});

// Stub until the native EventChannel lands (step 2); swap this one line then.
final connectivityMonitorProvider = Provider<ConnectivityMonitor>(
  (ref) => const StubConnectivityMonitor(),
);

final syncBlocProvider = Provider<SyncBloc>((ref) {
  final bloc = SyncBloc(
    outbox: ref.watch(outboxRepositoryProvider),
    registry: ref.watch(commandRegistryProvider),
    sender: ref.watch(commandSenderProvider),
    connectivity: ref.watch(connectivityMonitorProvider).onStatusChange,
  );
  ref.onDispose(bloc.close);
  return bloc;
});
