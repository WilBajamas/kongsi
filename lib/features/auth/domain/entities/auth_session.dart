import 'package:equatable/equatable.dart';
import 'package:kongsi/features/auth/domain/entities/app_user.dart';

sealed class AuthSession extends Equatable {
  const AuthSession();

  @override
  List<Object?> get props => [];
}

final class SignedOut extends AuthSession {
  const SignedOut();
}

final class SignedIn extends AuthSession {
  const SignedIn(this.user);

  final AppUser user;

  @override
  List<Object?> get props => [user];
}
