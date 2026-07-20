import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kongsi/core/sync/command_registry.dart';
import 'package:kongsi/core/sync/command_sender.dart';
import 'package:kongsi/core/sync/outbox_repository.dart';
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
      } on Exception catch (error, stackTrace) {
        addError(error, stackTrace); // observer → logger
        await _outbox.recordFailure(slip.id);
        // Halt instead of skipping ahead: slips can depend on earlier ones
        // (an expense needs its group), so order is a correctness rule.
        emit(SyncFailure(error));
        return;
      }
    }

    emit(const SyncIdle());
  }
}
