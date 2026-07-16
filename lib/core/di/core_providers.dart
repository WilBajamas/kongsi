import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kongsi/core/config/app_config.dart';
import 'package:kongsi/core/database/app_database.dart';
import 'package:kongsi/core/logger/app_logger.dart';
import 'package:kongsi/core/network/auth_token_provider.dart';
import 'package:kongsi/core/network/dio_client.dart';
import 'package:kongsi/core/network/no_auth_token_provider.dart';
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
