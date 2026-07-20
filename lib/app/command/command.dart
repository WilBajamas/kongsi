import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

/// Wraps one async action and exposes its lifecycle, so a button can
/// disable itself while running and double-taps can't fire twice.
class Command extends Cubit<CommandState> {
  Command(this._action) : super(const CommandIdle());

  final Future<void> Function() _action;

  Future<void> execute() async {
    if (state is CommandRunning) return;
    emit(const CommandRunning());
    try {
      await _action();
      emit(const CommandIdle());
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      // Errors (bugs) stay unhandled on purpose; the global nets log them.
      emit(CommandFailure(error));
    }
  }
}
