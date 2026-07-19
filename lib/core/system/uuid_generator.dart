import 'package:uuid/uuid.dart';

abstract interface class UuidGenerator {
  String generate();
}

final class UuidV4Generator implements UuidGenerator {
  UuidV4Generator() : _uuid = const Uuid();

  final Uuid _uuid;

  @override
  String generate() => _uuid.v4();
}
