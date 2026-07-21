/// Why a push failed, in the only two shapes the drain cares about. The sender
/// decides which one; the bloc reacts to it — so the bloc never has to know
/// about transport (dio, status codes) to tell a bad slip from bad luck.
sealed class SendFailure implements Exception {
  const SendFailure(this.cause);

  /// The underlying error (e.g. a DioException), kept for logging.
  final Object cause;
}

/// The server understood the request and refused this specific command
/// (a 4xx): the slip is the problem, so resending it unchanged is pointless.
/// Counts toward the retry ceiling.
final class CommandRejected extends SendFailure {
  const CommandRejected(super.cause);
}

/// The command never got a verdict — offline, timeout, or a 5xx. Not the
/// slip's fault, so the drain halts and retries later without counting it.
final class DeliveryFailed extends SendFailure {
  const DeliveryFailed(super.cause);
}
