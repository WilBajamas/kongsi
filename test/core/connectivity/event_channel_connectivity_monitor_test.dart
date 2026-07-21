import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kongsi/core/connectivity/connectivity_status.dart';
import 'package:kongsi/core/connectivity/event_channel_connectivity_monitor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = EventChannel('kongsi/connectivity');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockStreamHandler(channel, null));

  test('maps native strings to status and collapses repeats', () async {
    messenger.setMockStreamHandler(
      channel,
      MockStreamHandler.inline(
        onListen: (arguments, sink) {
          sink
            ..success('online')
            ..success('online') // duplicate → collapsed by distinct
            ..success('offline')
            ..endOfStream();
        },
      ),
    );

    // Uses the same channel name the mock is registered on (the default).
    const monitor = EventChannelConnectivityMonitor();

    await expectLater(
      monitor.onStatusChange,
      emitsInOrder([
        ConnectivityStatus.online,
        ConnectivityStatus.offline,
        emitsDone,
      ]),
    );
  });
}
