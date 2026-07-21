import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kongsi/core/connectivity/connectivity_status.dart';
import 'package:kongsi/core/database/app_database.dart';
import 'package:kongsi/core/database/tables/outbox_table.dart';
import 'package:kongsi/core/sync/command.dart';
import 'package:kongsi/core/sync/command_registry.dart';
import 'package:kongsi/core/sync/command_sender.dart';
import 'package:kongsi/core/sync/outbox_repository.dart';
import 'package:kongsi/core/sync/send_failure.dart';
import 'package:kongsi/core/sync/sync_bloc.dart';
import 'package:kongsi/core/sync/sync_event.dart';
import 'package:kongsi/features/groups/domain/commands/create_group_command.dart';

/// Every slip decodes to a real CreateGroupCommand, so the tests exercise the
/// drain through the actual registry rather than a stubbed decode.
final _registry = CommandRegistry([
  (type: CreateGroupCommand.type, fromJson: CreateGroupCommand.fromJson),
]);

OutboxRow _pendingSlip(int id) {
  final command = CreateGroupCommand(
    groupId: 'g$id',
    name: 'Trip',
    currency: 'MYR',
    createdAt: DateTime.utc(2026, 7, 20),
  );
  return OutboxRow(
    id: id,
    commandType: command.commandType,
    payloadJson: jsonEncode(command.toJson()),
    createdAt: DateTime.utc(2026, 7, 20),
    attempts: 0,
    status: OutboxStatus.pending,
  );
}

/// In-memory outbox that mutates like the real one: recordFailure bumps the
/// attempt count, markFailed parks the slip so getPending stops returning it.
class _FakeOutbox implements OutboxRepository {
  _FakeOutbox(this._slips);

  final List<OutboxRow> _slips;
  final deleted = <int>[];
  final markedFailed = <int>[];

  int attemptsFor(int id) => _slips.firstWhere((s) => s.id == id).attempts;

  @override
  Future<List<OutboxRow>> getPending() async =>
      _slips.where((s) => s.status == OutboxStatus.pending).toList()
        ..sort((a, b) => a.id.compareTo(b.id));

  @override
  Future<void> delete(int id) async {
    deleted.add(id);
    _slips.removeWhere((s) => s.id == id);
  }

  @override
  Future<void> recordFailure(int id) async {
    final i = _slips.indexWhere((s) => s.id == id);
    _slips[i] = _slips[i].copyWith(attempts: _slips[i].attempts + 1);
  }

  @override
  Future<void> markFailed(int id) async {
    markedFailed.add(id);
    final i = _slips.indexWhere((s) => s.id == id);
    _slips[i] = _slips[i].copyWith(status: OutboxStatus.failed);
  }
}

class _ThrowingSender implements CommandSender {
  _ThrowingSender(this._error);

  final SendFailure _error;
  int sent = 0;

  @override
  Future<void> send(Command command) async {
    sent++;
    throw _error;
  }
}

class _OkSender implements CommandSender {
  int sent = 0;

  @override
  Future<void> send(Command command) async => sent++;
}

/// Most tests don't care about connectivity, so it defaults to a stream that
/// never emits — the drain is driven by explicit SyncRequested events instead.
SyncBloc _blocWith(
  _FakeOutbox outbox,
  CommandSender sender, {
  Stream<ConnectivityStatus> connectivity =
      const Stream<ConnectivityStatus>.empty(),
}) {
  return SyncBloc(
    outbox: outbox,
    registry: _registry,
    sender: sender,
    connectivity: connectivity,
  );
}

void main() {
  test('a successful send deletes the slip', () async {
    final outbox = _FakeOutbox([_pendingSlip(1)]);
    final sender = _OkSender();
    final bloc = _blocWith(outbox, sender);
    addTearDown(bloc.close);

    bloc.add(const SyncRequested());
    await pumpEventQueue();

    expect(outbox.deleted, [1]);
    expect(sender.sent, 1);
  });

  test('a rejected slip is dead-lettered exactly on the 5th attempt', () async {
    final outbox = _FakeOutbox([_pendingSlip(1)]);
    final sender = _ThrowingSender(const CommandRejected('nope'));
    final bloc = _blocWith(outbox, sender);
    addTearDown(bloc.close);

    // First four drains: counted, but not yet dead-lettered.
    for (var attempt = 1; attempt <= 4; attempt++) {
      bloc.add(const SyncRequested());
      await pumpEventQueue();
      expect(outbox.markedFailed, isEmpty, reason: 'too early at $attempt');
      expect(outbox.attemptsFor(1), attempt);
    }

    // Fifth drain hits the ceiling.
    bloc.add(const SyncRequested());
    await pumpEventQueue();
    expect(outbox.markedFailed, [1]);
    expect(sender.sent, 5);

    // Sixth drain: the failed slip is skipped, so the sender isn't called.
    bloc.add(const SyncRequested());
    await pumpEventQueue();
    expect(sender.sent, 5, reason: 'a dead-lettered slip is not retried');
  });

  test(
    'an offline slip is retried forever, never counted or dead-lettered',
    () async {
      final outbox = _FakeOutbox([_pendingSlip(1)]);
      final sender = _ThrowingSender(const DeliveryFailed('offline'));
      final bloc = _blocWith(outbox, sender);
      addTearDown(bloc.close);

      for (var i = 0; i < 10; i++) {
        bloc.add(const SyncRequested());
        await pumpEventQueue();
      }

      expect(sender.sent, 10, reason: 'kept trying every drain');
      expect(
        outbox.attemptsFor(1),
        0,
        reason: "offline is not the slip's fault",
      );
      expect(outbox.markedFailed, isEmpty);
    },
  );

  group('connectivity trigger', () {
    test('a return to online drains the outbox', () async {
      final outbox = _FakeOutbox([_pendingSlip(1)]);
      final sender = _OkSender();
      final connectivity = StreamController<ConnectivityStatus>();
      final bloc = _blocWith(outbox, sender, connectivity: connectivity.stream);
      addTearDown(bloc.close);
      addTearDown(connectivity.close);

      connectivity.add(ConnectivityStatus.online);
      await pumpEventQueue();

      expect(sender.sent, 1);
      expect(outbox.deleted, [1]);
    });

    test('going offline does not drain', () async {
      final outbox = _FakeOutbox([_pendingSlip(1)]);
      final sender = _OkSender();
      final connectivity = StreamController<ConnectivityStatus>();
      final bloc = _blocWith(outbox, sender, connectivity: connectivity.stream);
      addTearDown(bloc.close);
      addTearDown(connectivity.close);

      connectivity.add(ConnectivityStatus.offline);
      await pumpEventQueue();

      expect(sender.sent, 0);
      expect(outbox.deleted, isEmpty);
    });

    test('a closed bloc stops draining on reconnect', () async {
      final outbox = _FakeOutbox([_pendingSlip(1)]);
      final sender = _OkSender();
      final connectivity = StreamController<ConnectivityStatus>();
      final bloc = _blocWith(outbox, sender, connectivity: connectivity.stream);
      addTearDown(connectivity.close);

      await bloc.close();
      connectivity.add(ConnectivityStatus.online);
      await pumpEventQueue();

      expect(sender.sent, 0, reason: 'a closed bloc must not drain');
    });
  });
}
