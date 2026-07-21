import 'package:kongsi/core/sync/command.dart';
import 'package:kongsi/core/sync/send_failure.dart';

/// The seam between draining and pushing — SyncBloc hands each command here
/// without knowing where it goes.
abstract interface class CommandSender {
  /// Throws a [SendFailure] on failure; its subtype tells the drain whether to
  /// count the slip against the retry ceiling.
  Future<void> send(Command command);
}
