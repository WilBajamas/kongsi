import 'package:equatable/equatable.dart';

sealed class SyncProblemsState extends Equatable {
  const SyncProblemsState();

  @override
  List<Object?> get props => [];
}

/// Nothing is stuck — the banner stays out of the way entirely.
final class SyncProblemsNone extends SyncProblemsState {
  const SyncProblemsNone();
}

/// Holds ids, not outbox rows: presentation never needs the payload, and
/// keeping Drift's row type out of this layer is the same boundary the
/// repositories draw for entities.
final class SyncProblemsFound extends SyncProblemsState {
  const SyncProblemsFound(this.failedIds);

  final List<int> failedIds;

  @override
  List<Object?> get props => [failedIds];
}
