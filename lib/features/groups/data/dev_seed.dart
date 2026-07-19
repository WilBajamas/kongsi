import 'package:kongsi/core/database/app_database.dart';
import 'package:kongsi/core/system/clock.dart';
import 'package:kongsi/core/system/uuid_generator.dart';

/// Plants one demo group on a fresh dev install so the screen has data to
/// prove the pipeline before any create flow exists.
Future<void> seedDevGroups({
  required AppDatabase db,
  required Clock clock,
  required UuidGenerator uuid,
}) async {
  final existing = await db.select(db.groups).get();
  if (existing.isNotEmpty) return;

  await db
      .into(db.groups)
      .insert(
        GroupsCompanion.insert(
          id: uuid.generate(),
          name: 'Demo Group',
          currency: 'MYR',
          createdAt: clock.now(),
        ),
      );
}
