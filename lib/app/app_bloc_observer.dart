import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver(this._talker);

  final Talker _talker;

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    // Names the net and the bloc: with one observer for every bloc, the type
    // is the only clue about where the error came from.
    _talker.handle(error, stackTrace, 'net 4 · Bloc · ${bloc.runtimeType}');
    super.onError(bloc, error, stackTrace);
  }
}
