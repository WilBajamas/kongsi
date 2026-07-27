import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kongsi/app/sync_problems/cubits/sync_problems_cubit.dart';
import 'package:kongsi/app/sync_problems/widgets/sync_problems_banner.dart';
import 'package:kongsi/core/connectivity/connectivity_status.dart';
import 'package:kongsi/core/database/app_database.dart';
import 'package:kongsi/core/database/tables/outbox_table.dart';
import 'package:kongsi/core/sync/command.dart';
import 'package:kongsi/core/sync/command_registry.dart';
import 'package:kongsi/core/sync/command_sender.dart';
import 'package:kongsi/core/sync/outbox_repository.dart';
import 'package:kongsi/core/sync/sync_bloc.dart';

import '../../helpers/pump_app.dart';

OutboxRow _row(int id) => OutboxRow(
  id: id,
  commandType: 'create_group',
  payloadJson: '{}',
  createdAt: DateTime.utc(2026, 7, 27),
  attempts: 1,
  status: OutboxStatus.failed,
);

/// Only the dead-letter side matters here, so the drain methods are inert —
/// a fake rather than a mock because the test drives state over time.
class _FakeOutbox implements OutboxRepository {
  // Single-subscription on purpose: it buffers, so a test can emit before the
  // cubit has attached without the event being dropped.
  final _failed = StreamController<List<OutboxRow>>();
  final retried = <int>[];

  void emitFailed(List<int> ids) =>
      _failed.add([for (final id in ids) _row(id)]);

  @override
  Stream<List<OutboxRow>> watchFailed() => _failed.stream;

  @override
  Future<void> retry(int id) async => retried.add(id);

  @override
  Future<List<OutboxRow>> getPending() async => const [];

  @override
  Future<void> delete(int id) async {}

  @override
  Future<void> recordFailure(int id) async {}

  @override
  Future<void> markFailed(int id) async {}

  Future<void> dispose() => _failed.close();
}

class _NoopSender implements CommandSender {
  @override
  Future<void> send(Command command) async {}
}

void main() {
  late _FakeOutbox outbox;
  late SyncBloc sync;
  late SyncProblemsCubit cubit;

  setUp(() {
    outbox = _FakeOutbox();
    sync = SyncBloc(
      outbox: outbox,
      registry: CommandRegistry(const []),
      sender: _NoopSender(),
      connectivity: const Stream<ConnectivityStatus>.empty(),
    );
    cubit = SyncProblemsCubit(outbox, sync);
  });

  tearDown(() async {
    await cubit.close();
    await sync.close();
    await outbox.dispose();
  });

  Future<void> pumpBanner(WidgetTester tester) => tester.pumpApp(
    BlocProvider.value(
      value: cubit,
      child: const SyncProblemsBanner(
        child: Scaffold(body: Text('page content')),
      ),
    ),
  );

  /// The outbox → cubit → BlocBuilder chain crosses several microtask hops.
  /// `pump()` alone returns before the widget sees the new state, and
  /// `pumpEventQueue()` deadlocks here because widget tests run in a fake-async
  /// zone — so let the real event loop deliver, then render.
  Future<void> emitAndPump(WidgetTester tester, List<int> ids) async {
    await tester.runAsync(() async {
      outbox.emitFailed(ids);
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
  }

  testWidgets('stays out of the way when nothing is stuck', (tester) async {
    await pumpBanner(tester);
    await tester.pump();

    expect(find.byIcon(Icons.sync_problem), findsNothing);
    expect(find.text('page content'), findsOneWidget);
  });

  testWidgets('tells the user how many changes are stuck', (tester) async {
    await pumpBanner(tester);
    await emitAndPump(tester, [1, 2]);

    expect(find.text('2 changes could not be saved'), findsOneWidget);
    expect(
      find.text('page content'),
      findsOneWidget,
      reason: 'the banner sits above the page, it does not replace it',
    );
  });

  testWidgets('one stuck change reads as singular', (tester) async {
    await pumpBanner(tester);
    await emitAndPump(tester, [7]);

    expect(find.text('1 change could not be saved'), findsOneWidget);
  });

  testWidgets('retry re-queues every stuck change', (tester) async {
    await pumpBanner(tester);
    await emitAndPump(tester, [1, 2]);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(outbox.retried, [1, 2]);
  });
}
