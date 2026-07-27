import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kongsi/app/sync_problems/cubits/sync_problems_state.dart';
import 'package:kongsi/core/database/app_database.dart';
import 'package:kongsi/core/sync/outbox_repository.dart';
import 'package:kongsi/core/sync/sync_bloc.dart';
import 'package:kongsi/core/sync/sync_event.dart';

class SyncProblemsCubit extends Cubit<SyncProblemsState> {
  SyncProblemsCubit(this._outbox, this._sync)
    : super(const SyncProblemsNone()) {
    /// watches the dead-letter pile so a change can be reflected on the ui
    _subscription = _outbox.watchFailed().listen((rows) {
      emit(
        rows.isEmpty
            ? const SyncProblemsNone()
            : SyncProblemsFound([for (final row in rows) row.id]),
      );
    });
  }

  final OutboxRepository _outbox;
  final SyncBloc _sync;
  late final StreamSubscription<List<OutboxRow>> _subscription;

  /// Re-queues every stuck slip, then asks for a drain. Worth doing even
  /// though a rejection is permanent: what changed is usually *outside* the
  /// payload — a fixed server, a deploy, auth finally wired up.
  Future<void> retryAll() async {
    if (state case SyncProblemsFound(:final failedIds)) {
      for (final id in failedIds) {
        await _outbox.retry(id);
      }
      _sync.add(const SyncRequested());
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
