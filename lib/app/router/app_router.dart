import 'package:auto_route/auto_route.dart';
import 'package:kongsi/app/router/auth_guard.dart';
import 'package:kongsi/features/auth/presentation/pages/sign_in_page.dart';
import 'package:kongsi/features/auth/presentation/pages/sign_up_page.dart';
import 'package:kongsi/features/auth/presentation/pages/welcome_page.dart';
import 'package:kongsi/features/groups/presentation/pages/groups_page.dart';

part 'app_router.gr.dart';

/// The route table doubles as the deep-link contract, so paths are designed up
/// front even though only `/` is built — later features and invite links then
/// attach to a stable table instead of forcing a navigation rewrite.
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  AppRouter(this._authGuard);

  final AuthGuard _authGuard;

  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: GroupsRoute.page,
      path: '/',
      initial: true,
      guards: [_authGuard],
    ),
    AutoRoute(page: WelcomeRoute.page, path: '/welcome'),
    AutoRoute(page: SignInRoute.page, path: '/sign-in'),
    AutoRoute(page: SignUpRoute.page, path: '/sign-up'),
  ];
}
