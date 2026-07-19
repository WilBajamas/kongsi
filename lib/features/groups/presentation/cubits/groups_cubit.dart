import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kongsi/features/groups/domain/entities/group.dart';
import 'package:kongsi/features/groups/domain/use_cases/watch_groups_use_case.dart';
import 'package:kongsi/features/groups/presentation/cubits/groups_state.dart';

class GroupsCubit extends Cubit<GroupsState> {
  GroupsCubit(this._watchGroups) : super(const GroupsLoading()) {
    _subscription = _watchGroups().listen(
      (groups) => emit(GroupsLoaded(groups)),
    );
  }

  final WatchGroupsUseCase _watchGroups;
  late final StreamSubscription<List<Group>> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
