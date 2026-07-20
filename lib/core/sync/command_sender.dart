import 'package:kongsi/core/sync/command.dart';

/// The seam between draining and pushing: the SyncBloc drains slips and
/// hands each command here, without knowing where they go. Swapping the
/// implementation (stub → Supabase) is a one-line provider change.
abstract interface class CommandSender {
  /// Completes normally on success; throws on failure — the caller decides
  /// what a failure means for the queue.
  Future<void> send(Command command);
}
