import 'package:kongsi/core/database/app_database.dart';

/// Exposes the Drift row directly — the outbox is sync infrastructure, not
/// domain, so there's no entity to protect.
abstract interface class OutboxRepository {
  /// Oldest first: FIFO is a correctness rule (a create must land before its
  /// edits), not a preference.
  Future<List<OutboxRow>> getPending();

  Future<void> delete(int id);

  /// Counts the attempt - diagnostic only
  Future<void> recordFailure(int id);

  /// marks the slip as failed - stops blocking the queue
  Future<void> markFailed(int id);

  /// stream failed slips to notify users
  Stream<List<OutboxRow>> watchFailed();

  /// puts a dead-lettered slip back in the queue and keeps the id
  Future<void> retry(int id);
}
