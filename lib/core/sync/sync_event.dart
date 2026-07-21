sealed class SyncEvent {
  const SyncEvent();
}

/// Something wants the outbox drained — fired on launch and on reconnect.
final class SyncRequested extends SyncEvent {
  const SyncRequested();
}
