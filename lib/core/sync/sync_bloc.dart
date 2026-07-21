import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kongsi/core/sync/command_registry.dart';
import 'package:kongsi/core/sync/command_sender.dart';
import 'package:kongsi/core/sync/outbox_repository.dart';
import 'package:kongsi/core/sync/send_failure.dart';
import 'package:kongsi/core/sync/sync_event.dart';
import 'package:kongsi/core/sync/sync_state.dart';

/// Drains the outbox: pending slips go through the registry (bytes → typed
/// command) to the sender (stub now, Supabase later). App-lifetime — created
/// once by the provider graph, never tied to a screen.
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  SyncBloc({
    required this._outbox,
    required this._registry,
    required this._sender,
  }) : super(const SyncIdle()) {
    on<SyncRequested>(_onSyncRequested);
  }

  final OutboxRepository _outbox;
  final CommandRegistry _registry;
  final CommandSender _sender;

  /// How many times a slip may be rejected before it's dead-lettered. Only
  /// the slip's own fault counts (see below) — being offline never does.
  static const _maxAttempts = 5;

  Future<void> _onSyncRequested(
    SyncRequested event,
    Emitter<SyncState> emit,
  ) async {
    emit(const SyncInProgress());

    final pending = await _outbox.getPending();
    for (final slip in pending) {
      try {
        final command = _registry.decode(slip.commandType, slip.payloadJson);
        await _sender.send(command);
        // Only delete after the send succeeded: a crash in between just
        // means one duplicate push, which client-generated ids make safe.
        await _outbox.delete(slip.id);
      } on DeliveryFailed catch (error, stackTrace) {
        // Not the slip's fault (offline, 5xx). Halt and retry next trigger,
        // and crucially don't count it — or being offline would eventually
        // dead-letter a perfectly good slip.
        addError(error, stackTrace); // observer → logger
        emit(SyncFailure(error));
        return;
      } on Object catch (error, stackTrace) {
        // Everything else is the slip's own fault — rejected by the server, or
        // it can't even be decoded. Retrying it unchanged won't help, so count
        // the attempt and, once the ceiling is hit, dead-letter it so it stops
        // blocking the queue.
        addError(error, stackTrace);
        await _outbox.recordFailure(slip.id);
        if (slip.attempts + 1 >= _maxAttempts) {
          await _outbox.markFailed(slip.id);
        }
        // Halt instead of skipping ahead: slips can depend on earlier ones
        // (an expense needs its group), so order is a correctness rule.
        emit(SyncFailure(error));
        return;
      }
    }

    emit(const SyncIdle());
  }
}
