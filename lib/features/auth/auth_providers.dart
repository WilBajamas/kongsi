import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kongsi/core/di/core_providers.dart';
import 'package:kongsi/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:kongsi/features/auth/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(ref.watch(goTrueClientProvider)),
);
