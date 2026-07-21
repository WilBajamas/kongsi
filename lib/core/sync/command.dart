abstract class Command {
  String get commandType;

  /// Kept separate from [toRow] so the on-disk format and the server schema
  /// can change independently.
  Map<String, dynamic> toJson();

  String get table;
  Map<String, dynamic> toRow();
}
