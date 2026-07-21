import 'package:kongsi/core/connectivity/connectivity_monitor.dart';
import 'package:kongsi/core/connectivity/connectivity_status.dart';

/// Placeholder until the native EventChannel exists (step 2). Emits nothing,
/// so sync stays exactly as it is today — launch-triggered only. Swapping this
/// for the real monitor is a one-line provider change.
class StubConnectivityMonitor implements ConnectivityMonitor {
  const StubConnectivityMonitor();

  @override
  Stream<ConnectivityStatus> get onStatusChange =>
      const Stream<ConnectivityStatus>.empty();
}
