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
      // Cross-OS anti-aliasing shifts a handful of edge pixels; real UI
      // changes move thousands.
      ciGoldensConfig: const CiGoldensConfig(diffThreshold: 0.001),
    ),
    run: testMain,
  );
}
