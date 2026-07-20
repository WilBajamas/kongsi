/// Events are *things that happened* that the bloc reacts to — unlike a
/// Cubit's methods, callers don't invoke behavior, they report occurrences.
/// More arrive later: connectivity restored, retry timer fired.
sealed class SyncEvent {
  const SyncEvent();
}

/// Something wants the outbox drained (currently: app launch).
final class SyncRequested extends SyncEvent {
  const SyncRequested();
}
