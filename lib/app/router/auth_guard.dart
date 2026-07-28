import 'package:auto_route/auto_route.dart';
import 'package:kongsi/app/router/app_router.dart';
import 'package:kongsi/features/auth/domain/entities/auth_session.dart';
import 'package:kongsi/features/auth/domain/repositories/auth_repository.dart';

/// Sends signed-out users to Welcome.
class AuthGuard extends AutoRouteGuard {
  const AuthGuard(this._repository);

  final AuthRepository _repository;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (_repository.currentSession is SignedIn) {
      resolver.next();
      return;
    }
    resolver.redirectUntil(const WelcomeRoute());
  }
}
