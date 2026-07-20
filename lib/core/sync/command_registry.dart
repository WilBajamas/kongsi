import 'dart:convert';

import 'package:kongsi/core/sync/command.dart';

typedef CommandFactory = Command Function(Map<String, dynamic> json);

typedef CommandRegistration = ({String type, CommandFactory fromJson});

/// Maps a stored `command_type` string back to the factory that can rebuild
/// the typed command. Serializing is easy (the object knows its own toJson);
/// this solves the reverse direction for rows read back from the outbox.
///
/// Built complete from a declarative catalog and immutable after — late or
/// duplicate registration is a state that cannot exist.
class CommandRegistry {
  CommandRegistry(List<CommandRegistration> registrations)
    : _factories = {
        for (final registration in registrations)
          registration.type: registration.fromJson,
      };

  final Map<String, CommandFactory> _factories;

  Command decode(String type, String payloadJson) {
    final factory = _factories[type];
    if (factory == null) {
      // An unregistered type means a programming error (missing catalog
      // entry), not bad data — so throw loudly instead of skipping quietly.
      throw StateError('No command factory registered for "$type"');
    }
    return factory(jsonDecode(payloadJson) as Map<String, dynamic>);
  }
}
