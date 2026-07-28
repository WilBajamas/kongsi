import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kongsi/app/router/app_router.dart';
import 'package:kongsi/app/theme/app_theme_dimensions.dart';
import 'package:kongsi/core/validation/validators.dart';
import 'package:kongsi/features/auth/auth_providers.dart';
import 'package:kongsi/features/auth/presentation/cubits/sign_in_cubit.dart';
import 'package:kongsi/features/auth/presentation/cubits/sign_in_state.dart';
import 'package:kongsi/l10n/gen/app_localizations.dart';
import 'package:kongsi/l10n/l10n_extension.dart';

@RoutePage()
class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(SignInCubit cubit) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await cubit.submit(email: _email.text.trim(), password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_) => SignInCubit(ref.read(authRepositoryProvider)),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.signInTitle)),
        body: BlocConsumer<SignInCubit, SignInState>(
          listener: (context, state) {
            if (state is SignInSucceeded) {
              unawaited(context.router.replaceAll([const GroupsRoute()]));
            }
          },
          builder: (context, state) {
            final busy = state is SignInSubmitting || state is SignInSucceeded;
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.p24,
                  vertical: AppSpacing.p16,
                ),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteractionIfError,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _email,
                        enabled: !busy,
                        autofillHints: const [AutofillHints.email],
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(labelText: l10n.emailLabel),
                        validator: (value) =>
                            isValidEmail(value) ? null : l10n.emailInvalid,
                      ),
                      const SizedBox(height: AppSpacing.p16),
                      TextFormField(
                        controller: _password,
                        enabled: !busy,
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: l10n.passwordLabel,
                        ),
                        onFieldSubmitted: (_) =>
                            _submit(context.read<SignInCubit>()),
                        validator: (value) => isValidPassword(value)
                            ? null
                            : l10n.passwordTooShort,
                      ),
                      if (_messageFor(state, l10n) case final message?) ...[
                        const SizedBox(height: AppSpacing.p16),
                        Text(
                          message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.p24),
                      FilledButton(
                        onPressed: busy
                            ? null
                            : () => _submit(context.read<SignInCubit>()),
                        child: busy
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.authContinue),
                      ),
                      const SizedBox(height: AppSpacing.p16),
                      Text(
                        l10n.authLegalFootnote,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

String? _messageFor(SignInState state, AppLocalizations l10n) =>
    switch (state) {
      SignInRejected() => l10n.authFailedCredentials,
      SignInUnavailable() => l10n.authFailedNetwork,
      SignInFailed() => l10n.authFailedUnknown,
      SignInIdle() || SignInSubmitting() || SignInSucceeded() => null,
    };
