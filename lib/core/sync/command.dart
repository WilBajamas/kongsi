abstract class Command {
  String get commandType;
  Map<String, dynamic> toJson();
}
