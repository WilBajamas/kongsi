import 'package:kongsi/core/database/app_database.dart';
import 'package:kongsi/features/groups/domain/entities/group.dart';

extension GroupRowMapper on GroupRow {
  Group toEntity() =>
      Group(id: id, name: name, currency: currency, createdAt: createdAt);
}
