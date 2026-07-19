import 'package:equatable/equatable.dart';
import 'package:kongsi/features/groups/domain/entities/group.dart';

sealed class GroupsState extends Equatable {
  const GroupsState();

  @override
  List<Object?> get props => [];
}

/// Before the first database emission arrives.
final class GroupsLoading extends GroupsState {
  const GroupsLoading();
}

/// Holds the current list; an empty list is valid data, not a separate state.
final class GroupsLoaded extends GroupsState {
  const GroupsLoaded(this.groups);

  final List<Group> groups;

  @override
  List<Object?> get props => [groups];
}
