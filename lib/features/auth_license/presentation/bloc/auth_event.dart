abstract class AuthEvent {}

class RequestOtpEvent extends AuthEvent {
  final String mobile;
  RequestOtpEvent(this.mobile);
}

class VerifyOtpEvent extends AuthEvent {
  final String mobile;
  final String code;
  VerifyOtpEvent(this.mobile, this.code);
}
