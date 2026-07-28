import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kongsi/features/auth/domain/entities/auth_session.dart';

/// Listens and notifies when the auth session changes
class SessionListenable extends ChangeNotifier {
  SessionListenable(Stream<AuthSession> sessions) {
    _subscription = sessions.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthSession> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
