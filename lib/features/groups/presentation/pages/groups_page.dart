import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kongsi/features/groups/groups_providers.dart';
import 'package:kongsi/features/groups/presentation/cubits/groups_cubit.dart';
import 'package:kongsi/features/groups/presentation/cubits/groups_state.dart';
import 'package:kongsi/features/groups/presentation/widgets/create_group_dialog.dart';
import 'package:kongsi/l10n/l10n_extension.dart';

@RoutePage()
class GroupsPage extends ConsumerWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BlocProvider(
      // read, not watch: create runs once and must not rebind.
      create: (_) => GroupsCubit(ref.read(watchGroupsUseCaseProvider)),
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const CreateGroupDialog(),
          ),
          child: const Icon(Icons.add),
        ),
        body: BlocBuilder<GroupsCubit, GroupsState>(
          builder: (context, state) => switch (state) {
            GroupsLoading() => const Center(child: CircularProgressIndicator()),
            GroupsLoaded(:final groups) when groups.isEmpty => Center(
              child: Text(context.l10n.groupsEmpty),
            ),
            GroupsLoaded(:final groups) => ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(groups[index].name),
                subtitle: Text(groups[index].currency),
              ),
            ),
          },
        ),
      ),
    );
  }
}
