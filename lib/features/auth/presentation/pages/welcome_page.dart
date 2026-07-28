import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:kongsi/app/router/app_router.dart';
import 'package:kongsi/app/theme/app_theme_dimensions.dart';
import 'package:kongsi/l10n/l10n_extension.dart';

@RoutePage()
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(l10n.appTitle, style: theme.textTheme.displayMedium),
              const SizedBox(height: AppSpacing.p12),
              Text(
                l10n.welcomePromise,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.router.push(const SignUpRoute()),
                child: Text(l10n.welcomeGetStarted),
              ),
              const SizedBox(height: AppSpacing.p8),
              TextButton(
                onPressed: () => context.router.push(const SignInRoute()),
                child: Text(l10n.welcomeHaveAccount),
              ),
              const SizedBox(height: AppSpacing.p24),
            ],
          ),
        ),
      ),
    );
  }
}
