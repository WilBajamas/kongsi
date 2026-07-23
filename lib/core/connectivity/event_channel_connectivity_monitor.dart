import 'package:flutter/services.dart';
import 'package:kongsi/core/connectivity/connectivity_monitor.dart';
import 'package:kongsi/core/connectivity/connectivity_status.dart';

/// Real monitor: native emits `'online'`/`'offline'` strings over an EventChannel.
class EventChannelConnectivityMonitor implements ConnectivityMonitor {
  const EventChannelConnectivityMonitor([
    this._channel = const EventChannel('kongsi/connectivity'),
  ]);

  final EventChannel _channel;

  @override
  Stream<ConnectivityStatus> get onStatusChange => _channel
      .receiveBroadcastStream()
      .map(
        (event) => event == 'online'
            ? ConnectivityStatus.online
            : ConnectivityStatus.offline,
      )
      // `distinct` skips data events if they are equal to the previous event.
      // ! DO NOT REMOVE distinct
      .distinct();
}
