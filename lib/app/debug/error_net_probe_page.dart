import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kongsi/core/di/core_providers.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Dev-only. Fires one deliberate error into each of the four global nets laid
/// down in `bootstrap.dart`, so "all four funnel into one logger" stops being a
/// claim and becomes something observed (charter §6-A Definition of Done).
///
/// Not in the auto_route table on purpose: that table is the deep-link
/// contract, and a debug screen has no business being addressable.
class ErrorNetProbePage extends ConsumerWidget {
  const ErrorNetProbePage({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const ErrorNetProbePage());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final talker = ref.watch(talkerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Error net probe')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Each button throws into one net. Open the log afterwards and '
            'confirm the error landed there — that is the verification.',
          ),
          const SizedBox(height: 24),

          _Probe(
            net: '1',
            label: 'Framework error (throw in a build method)',
            expectation: 'FlutterError.onError',
            onFire: () => showDialog<void>(
              context: context,
              builder: (_) => const _BuildBomb(),
            ),
          ),

          _Probe(
            net: '2 / 3',
            label: 'Async error with no local handler',
            expectation:
                'Expected to land in runZonedGuarded (net 3), NOT '
                'PlatformDispatcher.onError (net 2) — bootstrap runs the whole '
                'app inside the guarded zone, so the zone handler wins. Net 2 '
                'is a backstop for errors raised outside that zone. Confirm '
                'which one actually catches it.',
            onFire: () => unawaited(
              Future<void>.delayed(
                Duration.zero,
                () => throw StateError('probe: async, no local handler'),
              ),
            ),
          ),

          _Probe(
            net: '3',
            label: 'Uncaught microtask error',
            expectation: 'runZonedGuarded',
            onFire: () => scheduleMicrotask(
              () => throw StateError('probe: uncaught microtask'),
            ),
          ),

          _Probe(
            net: '4',
            label: 'Error raised inside a Cubit',
            expectation: 'Bloc.observer → AppBlocObserver',
            onFire: () {
              final cubit = _BoomCubit()..boom();
              unawaited(cubit.close());
            },
          ),

          const Divider(height: 40),
          FilledButton.icon(
            icon: const Icon(Icons.list_alt),
            label: const Text('Open the log'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TalkerScreen(talker: talker),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Probe extends StatelessWidget {
  const _Probe({
    required this.net,
    required this.label,
    required this.expectation,
    required this.onFire,
  });

  final String net;
  final String label;
  final String expectation;
  final VoidCallback onFire;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Text(net)),
        title: Text(label),
        subtitle: Text(expectation),
        isThreeLine: true,
        trailing: FilledButton.tonal(
          onPressed: onFire,
          child: const Text('Fire'),
        ),
      ),
    );
  }
}

/// Throws while building, which is what net 1 exists to catch. Flutter swaps
/// in its own error widget afterwards, so the dialog renders as the red box.
class _BuildBomb extends StatelessWidget {
  const _BuildBomb();

  @override
  Widget build(BuildContext context) =>
      throw StateError('probe: throw inside build');
}

class _BoomCubit extends Cubit<int> {
  _BoomCubit() : super(0);

  void boom() =>
      addError(StateError('probe: error inside a Cubit'), StackTrace.current);
}
