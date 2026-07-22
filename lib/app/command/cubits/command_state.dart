import 'package:equatable/equatable.dart';

sealed class CommandState extends Equatable {
  const CommandState();

  @override
  List<Object?> get props => [];
}

final class CommandIdle extends CommandState {
  const CommandIdle();
}

final class CommandRunning extends CommandState {
  const CommandRunning();
}

final class CommandFailure extends CommandState {
  const CommandFailure(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}
