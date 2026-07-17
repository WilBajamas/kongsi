import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kongsi/app/router/app_router.dart';

/// Provided via DI so future guards can read other providers (auth). Lives in
/// the app layer — `core` must never depend on `app`.
final appRouterProvider = Provider<AppRouter>((ref) => AppRouter());
