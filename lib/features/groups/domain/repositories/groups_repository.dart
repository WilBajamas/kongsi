import 'package:kongsi/features/groups/domain/entities/group.dart';

abstract interface class GroupsRepository {
  /// Emits the current groups and again on every change.
  Stream<List<Group>> watchGroups();

  Future<void> createGroup(Group group);
}
