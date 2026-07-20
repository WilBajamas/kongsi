import 'package:equatable/equatable.dart';

sealed class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

final class SyncIdle extends SyncState {
  const SyncIdle();
}

final class SyncInProgress extends SyncState {
  const SyncInProgress();
}

/// The last drain halted on a failing slip. Nothing renders this yet;
/// a sync-status indicator will, later.
final class SyncFailure extends SyncState {
  const SyncFailure(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}
