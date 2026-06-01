import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AuthEvent {}

class SubmitPhoneNumber extends AuthEvent {
  final String phoneNumber;
  SubmitPhoneNumber(this.phoneNumber);
}

class SubmitVerificationCode extends AuthEvent {
  final String code;
  SubmitVerificationCode(this.code);
}

class ResetToPhoneInput extends AuthEvent {}

class ResendVerificationCode extends AuthEvent {
  final String phoneNumber;
  ResendVerificationCode(this.phoneNumber);
}

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthCodeSent extends AuthState {
  final String phoneNumber;
  AuthCodeSent(this.phoneNumber);
}

class AuthSuccess extends AuthState {
  final String token;
  AuthSuccess(this.token);
}

class AuthFailure extends AuthState {
  final String errorDetails;
  AuthFailure(this.errorDetails);
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  String _currentPhoneNumber = "";

  AuthBloc() : super(AuthInitial()) {
    on<SubmitPhoneNumber>((event, emit) async {
      _currentPhoneNumber = event.phoneNumber;
      emit(AuthLoading());
      await Future.delayed(const Duration(seconds: 2));
      emit(AuthCodeSent(_currentPhoneNumber));
    });

    on<SubmitVerificationCode>((event, emit) async {
      emit(AuthLoading());
      await Future.delayed(const Duration(seconds: 2));
      if (event.code == "12345") {
        emit(AuthSuccess("SIMULATED_JWT_TOKEN_FROM_FASTAPI"));
      } else {
        emit(AuthFailure("Invalid verification code."));
        emit(AuthCodeSent(_currentPhoneNumber));
      }
    });

    on<ResetToPhoneInput>((event, emit) {
      emit(AuthInitial());
    });

    on<ResendVerificationCode>((event, emit) async {
      emit(AuthLoading());
      await Future.delayed(const Duration(seconds: 2));
      emit(AuthCodeSent(_currentPhoneNumber));
    });
  }
}
