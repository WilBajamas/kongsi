import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kongsi/core/di/core_providers.dart';

/// Temporary landing page; becomes the Groups screen once the ledger exists.
@RoutePage()
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    return Scaffold(
      body: Center(
        child: Text('Hello World! (${config.flavor.name})'),
      ),
    );
  }
}
