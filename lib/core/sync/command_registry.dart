import 'dart:convert';

import 'package:kongsi/core/sync/command.dart';

typedef CommandFactory = Command Function(Map<String, dynamic> json);

typedef CommandRegistration = ({String type, CommandFactory fromJson});

/// Rebuilds a typed command from a stored `command_type` + payload — the
/// reverse of toJson. Immutable once built from the catalog.
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
      // Unregistered type = a missing catalog entry (a bug), not bad data.
      throw StateError('No command factory registered for "$type"');
    }
    return factory(jsonDecode(payloadJson) as Map<String, dynamic>);
  }
}
