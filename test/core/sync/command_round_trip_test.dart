import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kongsi/core/sync/command_registry.dart';
import 'package:kongsi/features/groups/domain/commands/create_group_command.dart';

void main() {
  // Persisted slips outlive app versions, so a command must survive
  // serialize → store → deserialize unchanged. This test breaks the build
  // if a careless field rename would strand old queued slips.
  test('CreateGroupCommand survives the json round trip', () {
    final original = CreateGroupCommand(
      groupId: 'g1',
      name: 'Japan Trip',
      currency: 'MYR',
      createdAt: DateTime.utc(2026, 7, 20),
    );
    final registry = CommandRegistry([
      (type: CreateGroupCommand.type, fromJson: CreateGroupCommand.fromJson),
    ]);

    final decoded = registry.decode(
      CreateGroupCommand.type,
      jsonEncode(original.toJson()),
    );

    expect(decoded, isA<CreateGroupCommand>());
    expect(decoded.toJson(), original.toJson());
  });

  test('decoding an unregistered type throws', () {
    expect(
      () => CommandRegistry(const []).decode('unknown', '{}'),
      throwsStateError,
    );
  });
}
