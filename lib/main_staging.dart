import 'package:flutter/material.dart';

import 'package:kongsi/core/config/app_config.dart';
import 'package:kongsi/main.dart';

void main() {
  runApp(MainApp(config: AppConfig.fromEnvironment()));
}
