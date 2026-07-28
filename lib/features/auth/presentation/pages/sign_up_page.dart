import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kongsi/app/router/app_router.dart';
import 'package:kongsi/app/theme/app_theme_dimensions.dart';
import 'package:kongsi/core/validation/validators.dart';
import 'package:kongsi/features/auth/auth_providers.dart';
import 'package:kongsi/features/auth/presentation/cubits/sign_up_cubit.dart';
import 'package:kongsi/features/auth/presentation/cubits/sign_up_state.dart';
import 'package:kongsi/l10n/gen/app_localizations.dart';
import 'package:kongsi/l10n/l10n_extension.dart';

@RoutePage()
class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(SignUpCubit cubit) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await cubit.submit(email: _email.text.trim(), password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_) => SignUpCubit(ref.read(authRepositoryProvider)),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.signUpTitle)),
        body: BlocConsumer<SignUpCubit, SignUpState>(
          listener: (context, state) {
            if (state is SignUpSucceeded) {
              unawaited(context.router.replaceAll([const GroupsRoute()]));
            }
          },
          builder: (context, state) {
            final busy = state is SignUpSubmitting || state is SignUpSucceeded;
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
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: l10n.passwordLabel,
                        ),
                        onFieldSubmitted: (_) =>
                            _submit(context.read<SignUpCubit>()),
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
                            : () => _submit(context.read<SignUpCubit>()),
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

String? _messageFor(SignUpState state, AppLocalizations l10n) =>
    switch (state) {
      SignUpRejected() => l10n.authFailedCredentials,
      SignUpUnavailable() => l10n.authFailedNetwork,
      SignUpFailed() => l10n.authFailedUnknown,
      SignUpIdle() || SignUpSubmitting() || SignUpSucceeded() => null,
    };
