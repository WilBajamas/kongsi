import 'package:kongsi/core/sync/command.dart';
import 'package:kongsi/core/sync/command_sender.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Stand-in until a backend exists: "sends" a command by logging it.
/// Lets the whole drain pipeline run and be verified before Supabase is up.
class LoggingCommandSender implements CommandSender {
  const LoggingCommandSender(this._talker);

  final Talker _talker;

  @override
  Future<void> send(Command command) async {
    _talker.info(
      'sync stub: would push ${command.commandType} ${command.toJson()}',
    );
  }
}
