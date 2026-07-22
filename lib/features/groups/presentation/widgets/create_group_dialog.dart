import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kongsi/app/command/cubits/command_cubit.dart';
import 'package:kongsi/app/command/cubits/command_state.dart';
import 'package:kongsi/features/groups/groups_providers.dart';
import 'package:kongsi/l10n/l10n_extension.dart';

class CreateGroupDialog extends ConsumerStatefulWidget {
  const CreateGroupDialog({super.key});

  @override
  ConsumerState<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends ConsumerState<CreateGroupDialog> {
  final _name = TextEditingController();
  final _currency = TextEditingController(text: 'MYR');
  late final CommandCubit _submit;

  @override
  void initState() {
    super.initState();
    _submit = CommandCubit(
      () => ref.read(createGroupUseCaseProvider)(
        name: _name.text.trim(),
        currency: _currency.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _currency.dispose();
    unawaited(_submit.close());
    super.dispose();
  }

  Future<void> _create() async {
    if (_name.text.trim().isEmpty) return;
    await _submit.execute();
    if (_submit.state is! CommandFailure && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<CommandCubit, CommandState>(
      bloc: _submit,
      builder: (context, state) => AlertDialog(
        title: Text(l10n.createGroupTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.groupNameLabel),
            ),
            TextField(
              controller: _currency,
              decoration: InputDecoration(labelText: l10n.currencyLabel),
            ),
            if (state is CommandFailure)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  l10n.createGroupFailed,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: state is CommandRunning ? null : _create,
            child: state is CommandRunning
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.create),
          ),
        ],
      ),
    );
  }
}
