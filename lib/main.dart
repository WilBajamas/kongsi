import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kongsi/app/theme/app_theme.dart';
import 'package:kongsi/core/di/core_providers.dart';
import 'package:kongsi/l10n/gen/app_localizations.dart';
import 'package:kongsi/l10n/l10n_extension.dart';

void main() {
  runApp(
    const MainApp(),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // themeMode defaults to ThemeMode.system; user-controllable later.
      home: Scaffold(
        body: Center(
          child: Text('Hello World! (${config.flavor.name})'),
        ),
      ),
    );
  }
}
