import 'package:kongsi/core/database/app_database.dart';

/// Exposes the Drift row directly — the outbox is sync infrastructure, not
/// domain, so there's no entity to protect.
abstract interface class OutboxRepository {
  /// Oldest first: FIFO is a correctness rule (a create must land before its
  /// edits), not a preference.
  Future<List<OutboxRow>> getPending();

  Future<void> delete(int id);

  /// Counts the attempt; the retry ceiling reads this number.
  Future<void> recordFailure(int id);

  /// Parks the slip as `failed` so it drops out of getPending — the
  /// dead-letter that stops a poison slip blocking the queue.
  Future<void> markFailed(int id);
}
