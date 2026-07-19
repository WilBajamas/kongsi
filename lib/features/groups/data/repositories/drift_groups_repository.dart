import 'package:kongsi/core/database/app_database.dart';
import 'package:kongsi/features/groups/domain/entities/group.dart';
import 'package:kongsi/features/groups/domain/repositories/groups_repository.dart';

class DriftGroupsRepository implements GroupsRepository {
  DriftGroupsRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Group>> watchGroups() {
    return _db
        .select(_db.groups)
        .watch()
        .map(
          (rows) => rows.map(_toEntity).toList(),
        );
  }

  Group _toEntity(GroupRow row) => Group(
    id: row.id,
    name: row.name,
    currency: row.currency,
    createdAt: row.createdAt,
  );
}
