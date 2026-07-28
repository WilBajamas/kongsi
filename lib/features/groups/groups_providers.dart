import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kongsi/core/di/core_providers.dart';
import 'package:kongsi/features/groups/data/repositories/drift_groups_repository.dart';
import 'package:kongsi/features/groups/domain/repositories/groups_repository.dart';
import 'package:kongsi/features/groups/domain/use_cases/create_group_use_case.dart';

final groupsRepositoryProvider = Provider<GroupsRepository>(
  (ref) => DriftGroupsRepository(ref.watch(appDatabaseProvider)),
);

final createGroupUseCaseProvider = Provider<CreateGroupUseCase>(
  (ref) => CreateGroupUseCase(
    ref.watch(groupsRepositoryProvider),
    ref.watch(clockProvider),
    ref.watch(uuidGeneratorProvider),
  ),
);
