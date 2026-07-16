import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kongsi/core/config/app_config.dart';
import 'package:kongsi/core/di/core_providers.dart';

import 'package:kongsi/main.dart';

void main() {
  final config = AppConfig.fromEnvironment();
  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
      ],
      child: const MainApp(),
    ),
  );
}
