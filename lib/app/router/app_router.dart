import 'package:auto_route/auto_route.dart';
import 'package:kongsi/features/home/presentation/home_page.dart';

part 'app_router.gr.dart';

/// The route table doubles as the deep-link contract, so paths are designed up
/// front even though only `/` is built — later features and invite links then
/// attach to a stable table instead of forcing a navigation rewrite.
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeRoute.page, path: '/', initial: true),
  ];
}
