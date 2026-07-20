import 'package:kongsi/features/groups/domain/entities/group.dart';
import 'package:kongsi/features/groups/domain/repositories/groups_repository.dart';

/// In-memory stand-in so widget tests never touch a real database.
class MockGroupsRepository implements GroupsRepository {
  MockGroupsRepository(this._groups);

  final List<Group> _groups;

  @override
  Stream<List<Group>> watchGroups() => Stream.value(_groups);

  /// Records what [createGroup] was called with, for test assertions.
  final created = <Group>[];

  @override
  Future<void> createGroup(Group group) async {
    created.add(group);
  }
}
