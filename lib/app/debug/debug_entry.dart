import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kongsi/app/debug/error_net_probe_page.dart';
import 'package:kongsi/app/router/router_provider.dart';
import 'package:kongsi/core/config/app_config.dart';
import 'package:kongsi/core/di/core_providers.dart';

/// Dev-flavor-only entry to the debug tools. Lives app-wide rather than on a
/// feature page because it belongs to no feature — same reasoning as the sync
/// banner.
///
/// ! Anything built here sits ABOVE the Navigator, which is what supplies the
/// ! Overlay. So no Tooltip, no SnackBar, no dropdown/popup menu — they all
/// ! look up an Overlay and throw at build time. Same reason the button below
/// ! pushes through the router's key instead of Navigator.of(context).
class DebugEntry extends ConsumerWidget {
  const DebugEntry({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(appConfigProvider).flavor != Flavor.dev) return child;

    return Stack(
      children: [
        child,
        Positioned(
          left: 12,
          bottom: 12,
          child: SafeArea(
            child: Opacity(
              opacity: 0.6,
              child: FloatingActionButton.small(
                heroTag: 'debug-entry',
                onPressed: () => ref
                    .read(appRouterProvider)
                    .navigatorKey
                    .currentState
                    ?.push(ErrorNetProbePage.route()),
                child: const Icon(Icons.bug_report),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
