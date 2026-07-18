import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:kongsi/app/theme/app_theme.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(theme: AppTheme.light),
    run: testMain,
  );
}
