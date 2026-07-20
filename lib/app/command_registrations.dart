import 'package:kongsi/core/sync/command_registry.dart';
import 'package:kongsi/features/groups/domain/commands/create_group_command.dart';

/// The complete catalog of commands the app can sync. Lives in the app
/// layer because it must see every feature; core never imports features.
/// Every new mutation adds exactly one entry here.
const commandRegistrations = <CommandRegistration>[
  (type: CreateGroupCommand.type, fromJson: CreateGroupCommand.fromJson),
];
