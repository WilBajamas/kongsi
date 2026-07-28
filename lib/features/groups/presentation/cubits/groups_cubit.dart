import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kongsi/features/groups/domain/entities/group.dart';
import 'package:kongsi/features/groups/domain/repositories/groups_repository.dart';
import 'package:kongsi/features/groups/presentation/cubits/groups_state.dart';

class GroupsCubit extends Cubit<GroupsState> {
  GroupsCubit(this._repository) : super(const GroupsLoading()) {
    _subscription = _repository.watchGroups().listen(
      (groups) => emit(GroupsLoaded(groups)),
    );
  }

  final GroupsRepository _repository;
  late final StreamSubscription<List<Group>> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
