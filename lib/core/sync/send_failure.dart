/// Split so the drain can tell a bad slip from bad luck without knowing
/// anything about transport.
sealed class SendFailure implements Exception {
  const SendFailure(this.cause);

  final Object cause;
}

/// A 4xx — the slip itself is bad, so resending won't help. Counts against
/// the retry ceiling.
final class CommandRejected extends SendFailure {
  const CommandRejected(super.cause);
}

/// Offline, timeout, or 5xx — not the slip's fault, so retry without counting.
final class DeliveryFailed extends SendFailure {
  const DeliveryFailed(super.cause);
}
