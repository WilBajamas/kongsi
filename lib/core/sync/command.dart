abstract class Command {
  String get commandType;

  /// The outbox storage shape — stable, decoupled from the server schema.
  /// Written to the queue on the device; read back by the registry.
  Map<String, dynamic> toJson();

  /// The remote destination: the table this command lands in, and the row
  /// as the server expects it (snake_case columns). Kept separate from
  /// [toJson] so the on-disk format and the server schema can evolve apart.
  String get table;
  Map<String, dynamic> toRow();
}
