import 'package:drift/drift.dart';
import 'package:kongsi/core/database/app_database.dart';
import 'package:kongsi/core/database/tables/outbox_table.dart';
import 'package:kongsi/core/sync/outbox_repository.dart';

class DriftOutboxRepository implements OutboxRepository {
  DriftOutboxRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<OutboxRow>> getPending() {
    // id ordering = insertion order, and unlike createdAt it can't collide.
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
    // Increment in SQL: no read-modify-write race.
    return (_db.update(_db.outbox)..where((t) => t.id.equals(id))).write(
      OutboxCompanion.custom(attempts: _db.outbox.attempts + const Constant(1)),
    );
  }

  @override
  Future<void> markFailed(int id) {
    return (_db.update(_db.outbox)..where((t) => t.id.equals(id))).write(
      const OutboxCompanion(status: Value(OutboxStatus.failed)),
    );
  }

  @override
  Stream<List<OutboxRow>> watchFailed() {
    return (_db.select(_db.outbox)
          ..where((t) => t.status.equalsValue(OutboxStatus.failed))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .watch();
  }

  @override
  Future<void> retry(int id) {
    return (_db.update(_db.outbox)..where((t) => t.id.equals(id))).write(
      const OutboxCompanion(status: Value(OutboxStatus.pending)),
    );
  }
}
