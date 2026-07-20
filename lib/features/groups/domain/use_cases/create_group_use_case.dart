import 'package:kongsi/core/system/clock.dart';
import 'package:kongsi/core/system/uuid_generator.dart';
import 'package:kongsi/features/groups/domain/entities/group.dart';
import 'package:kongsi/features/groups/domain/repositories/groups_repository.dart';

class CreateGroupUseCase {
  const CreateGroupUseCase(this._repository, this._clock, this._uuid);

  final GroupsRepository _repository;
  final Clock _clock;
  final UuidGenerator _uuid;

  Future<void> call({required String name, required String currency}) {
    final group = Group(
      id: _uuid.generate(),
      name: name,
      currency: currency,
      createdAt: _clock.now(),
    );
    return _repository.createGroup(group);
  }
}
