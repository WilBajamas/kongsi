import 'package:json_annotation/json_annotation.dart';
import 'package:kongsi/core/sync/command.dart';

part 'create_group_command.g.dart';

@JsonSerializable()
class CreateGroupCommand implements Command {
  const CreateGroupCommand({
    required this.groupId,
    required this.name,
    required this.currency,
    required this.createdAt,
  });

  factory CreateGroupCommand.fromJson(Map<String, dynamic> json) =>
      _$CreateGroupCommandFromJson(json);

  static const type = 'create_group';

  final String groupId;
  final String name;
  final String currency;
  final DateTime createdAt;

  @override
  String get commandType => type;

  @override
  Map<String, dynamic> toJson() => _$CreateGroupCommandToJson(this);

  @override
  String get table => 'groups';

  @override
  Map<String, dynamic> toRow() => {
    'id': groupId,
    'name': name,
    'currency': currency,
    'created_at': createdAt.toIso8601String(),
  };
}
