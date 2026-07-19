import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:kongsi/app/theme/app_theme.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final isCI = Platform.environment.containsKey('CI');
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      theme: AppTheme.light,
      platformGoldensConfig: PlatformGoldensConfig(enabled: !isCI),
    ),
    run: testMain,
  );
}
