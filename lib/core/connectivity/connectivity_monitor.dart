import 'package:kongsi/core/connectivity/connectivity_status.dart';

/// Listens to network connectivity changes.
abstract interface class ConnectivityMonitor {
  /// Emits on each change in availability, already de-duplicated: a listener
  /// sees transitions (offline → online), not a stream of identical statuses.
  Stream<ConnectivityStatus> get onStatusChange;
}
