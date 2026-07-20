import 'package:drift/drift.dart';
import 'package:kongsi/core/database/app_database.dart';
import 'package:kongsi/core/database/tables/outbox_table.dart';
import 'package:kongsi/core/sync/outbox_repository.dart';

class DriftOutboxRepository implements OutboxRepository {
  DriftOutboxRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<OutboxRow>> getPending() {
    // Ordering by the autoincrement id gives insertion order for free —
    // unlike createdAt, it can never collide.
    return (_db.select(_db.outbox)
          ..where((t) => t.status.equalsValue(OutboxStatus.pending))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  @override
  Future<void> delete(int id) {
    return (_db.delete(_db.outbox)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> recordFailure(int id) {
    // attempts = attempts + 1 done in SQL, so there is no read-modify-write
    // race and no stale count.
    return (_db.update(_db.outbox)..where((t) => t.id.equals(id))).write(
      OutboxCompanion.custom(attempts: _db.outbox.attempts + const Constant(1)),
    );
  }
}
