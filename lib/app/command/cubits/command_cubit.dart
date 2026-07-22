import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kongsi/app/command/cubits/command_state.dart';

/// Wraps one async action and exposes its lifecycle, so a button can
/// disable itself while running and double-taps can't fire twice.
class CommandCubit extends Cubit<CommandState> {
  CommandCubit(this._action) : super(const CommandIdle());

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
