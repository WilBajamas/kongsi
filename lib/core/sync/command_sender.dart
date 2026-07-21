import 'package:kongsi/core/sync/command.dart';
import 'package:kongsi/core/sync/send_failure.dart';

/// The seam between draining and pushing: the SyncBloc drains slips and
/// hands each command here, without knowing where they go. Swapping the
/// implementation (stub → Supabase) is a one-line provider change.
abstract interface class CommandSender {
  /// Completes normally on success. On failure throws a [SendFailure] whose
  /// subtype tells the drain whether the slip was rejected (count it) or just
  /// undelivered (retry later) — so the caller never touches transport.
  Future<void> send(Command command);
}
