import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kongsi/app/theme/app_theme.dart';
import 'package:kongsi/core/di/core_providers.dart';

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
