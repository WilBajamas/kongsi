import 'package:kongsi/features/groups/domain/entities/group.dart';
import 'package:kongsi/features/groups/domain/repositories/groups_repository.dart';

class WatchGroupsUseCase {
  const WatchGroupsUseCase(this._repository);

  final GroupsRepository _repository;

  Stream<List<Group>> call() => _repository.watchGroups();
}
