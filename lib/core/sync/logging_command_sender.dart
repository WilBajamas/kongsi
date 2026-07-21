import 'package:kongsi/core/sync/command.dart';
import 'package:kongsi/core/sync/command_sender.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// A drop-in [CommandSender] that logs each command instead of pushing it.
/// Kept as the worked example of the sender seam: swap it for (or back from)
/// the Supabase sender in one line at `commandSenderProvider` — handy for
/// watching the drain without a backend.
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
