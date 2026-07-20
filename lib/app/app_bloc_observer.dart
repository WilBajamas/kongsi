import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver(this._talker);

  final Talker _talker;

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    _talker.handle(error, stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}
