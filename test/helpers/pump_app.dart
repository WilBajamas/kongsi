import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kongsi/app/theme/app_theme.dart';
import 'package:kongsi/core/di/core_providers.dart';
import 'package:kongsi/l10n/gen/app_localizations.dart';

import '../mocks/mock_app_config.dart';

extension PumpApp on WidgetTester {
  /// Pumps [child] under the same shell the real app uses — DI scope, theme,
  /// and localizations — with [mockAppConfig] injected so config-reading
  /// widgets resolve. Extra [overrides] stack on top.
  Future<void> pumpApp(
    Widget child, {
    List<Override> overrides = const [],
  }) {
    return pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(mockAppConfig),
          ...overrides,
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      ),
    );
  }
}
