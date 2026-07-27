import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kongsi/core/connectivity/connectivity_status.dart';
import 'package:kongsi/core/sync/command_registry.dart';
import 'package:kongsi/core/sync/command_sender.dart';
import 'package:kongsi/core/sync/outbox_repository.dart';
import 'package:kongsi/core/sync/send_failure.dart';
import 'package:kongsi/core/sync/sync_event.dart';
import 'package:kongsi/core/sync/sync_state.dart';

/// Drains the outbox: each pending slip is decoded via the registry and pushed
/// by the sender. App-lifetime, created once by the provider graph.
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  SyncBloc({
    required this._outbox,
    required this._registry,
    required this._sender,
    required Stream<ConnectivityStatus> connectivity,
  }) : super(const SyncIdle()) {
    // droppable: two triggers (launch + reconnect) can fire together — drop a
    // new request mid-drain so drains never race on the same slips.
    on<SyncRequested>(_onSyncRequested, transformer: droppable());

    // Flush on reconnect instead of waiting for the next launch.
    _connectivitySub = connectivity
        .where((status) => status == ConnectivityStatus.online)
        .listen((_) => add(const SyncRequested()));
  }

  final OutboxRepository _outbox;
  final CommandRegistry _registry;
  final CommandSender _sender;
  late final StreamSubscription<ConnectivityStatus> _connectivitySub;

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
        // Delete only after a successful send: a crash between is one duplicate
        // push, made safe by client-generated ids (at-least-once).
        await _outbox.delete(slip.id);
      } on DeliveryFailed catch (error, stackTrace) {
        // Not the slip's fault — halt and retry later, without counting it.
        addError(error, stackTrace);
        emit(SyncFailure(error));
        return;
      } on Object catch (error, stackTrace) {
        // Straight away mark as failed
        addError(error, stackTrace);
        await _outbox.recordFailure(slip.id); // diagnostic count only
        await _outbox.markFailed(slip.id);
        // emits the error to presentation to handle
        emit(SyncFailure(error));
        return;
      }
    }

    emit(const SyncIdle());
  }

  @override
  Future<void> close() async {
    await _connectivitySub.cancel();
    return super.close();
  }
}
