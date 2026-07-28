import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kongsi/app/router/app_router.dart';
import 'package:kongsi/app/router/auth_guard.dart';
import 'package:kongsi/app/router/session_listenable.dart';
import 'package:kongsi/features/auth/auth_providers.dart';

/// Provided via DI so guards can read other providers.
final appRouterProvider = Provider<AppRouter>(
  (ref) => AppRouter(AuthGuard(ref.watch(authRepositoryProvider))),
);

final sessionListenableProvider = Provider<SessionListenable>((ref) {
  final listenable = SessionListenable(
    ref.watch(authRepositoryProvider).watchSession(),
  );
  ref.onDispose(listenable.dispose);
  return listenable;
});
