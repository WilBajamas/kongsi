import 'package:kongsi/core/connectivity/connectivity_status.dart';

/// A source of network-availability changes. Backed later by a native
/// EventChannel; a stub stands in until then. The seam lets SyncBloc react to
/// reconnects without knowing where the signal comes from.
abstract interface class ConnectivityMonitor {
  /// Emits on each change in availability, already de-duplicated: a listener
  /// sees transitions (offline → online), not a stream of identical statuses.
  Stream<ConnectivityStatus> get onStatusChange;
}
