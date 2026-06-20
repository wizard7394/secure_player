abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpRequested extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String token;
  AuthAuthenticated(this.token);
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
