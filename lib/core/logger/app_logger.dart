import 'package:talker_flutter/talker_flutter.dart';

Talker createLogger() {
  return TalkerFlutter.init(
    settings: TalkerSettings(),
  );
}
