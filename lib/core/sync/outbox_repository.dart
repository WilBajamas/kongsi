import 'package:kongsi/core/database/app_database.dart';

/// Data access for outbox slips. Exposes the Drift row type directly:
/// the outbox is sync infrastructure, not domain — there is no "purer"
/// shape of a slip for an entity to protect.
abstract interface class OutboxRepository {
  /// Pending slips, oldest first — FIFO order is a correctness rule,
  /// not a preference (a create must reach the server before its edits).
  Future<List<OutboxRow>> getPending();

  /// Called after a successful push: the slip's job is done.
  Future<void> delete(int id);

  /// Called after a failed push: keeps the slip, counts the attempt
  /// (the retry ceiling reads this number).
  Future<void> recordFailure(int id);

  /// Called once the ceiling is hit: parks the slip as `failed` so it drops
  /// out of getPending and stops blocking the queue. Dead-letter — nothing
  /// retries it automatically.
  Future<void> markFailed(int id);
}
