import 'package:drift/drift.dart';

@DataClassName('GroupRow')
class Groups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get currency => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
