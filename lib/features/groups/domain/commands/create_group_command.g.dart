// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_group_command.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateGroupCommand _$CreateGroupCommandFromJson(Map<String, dynamic> json) =>
    CreateGroupCommand(
      groupId: json['groupId'] as String,
      name: json['name'] as String,
      currency: json['currency'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$CreateGroupCommandToJson(CreateGroupCommand instance) =>
    <String, dynamic>{
      'groupId': instance.groupId,
      'name': instance.name,
      'currency': instance.currency,
      'createdAt': instance.createdAt.toIso8601String(),
    };
