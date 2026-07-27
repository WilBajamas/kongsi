import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kongsi/app/debug/debug_entry.dart';
import 'package:kongsi/app/router/router_provider.dart';
import 'package:kongsi/app/sync_problems/cubits/sync_problems_cubit.dart';
import 'package:kongsi/app/sync_problems/widgets/sync_problems_banner.dart';
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
    final router = ref.watch(appRouterProvider);
    // Above MaterialApp so the cubit outlives route changes; the banner reads
    // it from the builder below, which sits inside MaterialApp's Localizations.
    return BlocProvider(
      create: (_) => SyncProblemsCubit(
        ref.read(outboxRepositoryProvider),
        ref.read(syncBlocProvider),
      ),
      child: MaterialApp.router(
        routerConfig: router.config(),
        onGenerateTitle: (context) => context.l10n.appTitle,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        // themeMode defaults to ThemeMode.system; user-controllable later.
        builder: (context, child) => DebugEntry(
          child: SyncProblemsBanner(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}
