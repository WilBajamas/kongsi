import 'dart:convert';

import 'package:kongsi/core/database/app_database.dart';
import 'package:kongsi/core/database/tables/outbox_table.dart';
import 'package:kongsi/features/groups/data/mappers/group_mapper.dart';
import 'package:kongsi/features/groups/domain/commands/create_group_command.dart';
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
          (rows) => [for (final row in rows) row.toEntity()],
        );
  }

  @override
  Future<void> createGroup(Group group) {
    final Group(:id, :createdAt, :name, :currency) = group;

    return _db.transaction(() async {
      await _db
          .into(_db.groups)
          .insert(
            GroupsCompanion.insert(
              id: id,
              name: name,
              currency: currency,
              createdAt: createdAt,
            ),
          );

      await _db
          .into(_db.outbox)
          .insert(
            OutboxCompanion.insert(
              commandType: CreateGroupCommand.type,
              payloadJson: jsonEncode(
                CreateGroupCommand(
                  groupId: id,
                  name: name,
                  currency: currency,
                  createdAt: createdAt,
                ).toJson(),
              ),
              createdAt: createdAt,
              status: OutboxStatus.pending,
            ),
          );
    });
  }
}
