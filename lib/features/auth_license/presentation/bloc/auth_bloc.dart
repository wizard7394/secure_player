import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

class RequestOtpEvent extends AuthEvent {
  final String phone;
  const RequestOtpEvent({required this.phone});
  @override
  List<Object> get props => [phone];
}

class VerifyOtpEvent extends AuthEvent {
  final String phone;
  final String code;
  const VerifyOtpEvent({required this.phone, required this.code});
  @override
  List<Object> get props => [phone, code];
}

class ResetAuthEvent extends AuthEvent {}

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class OtpSentState extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String token;
  const AuthAuthenticated({required this.token});
  @override
  List<Object> get props => [token];
}

class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});
  @override
  List<Object> get props => [message];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiClient apiClient;

  AuthBloc({required this.apiClient}) : super(AuthInitial()) {
    on<RequestOtpEvent>(_onRequestOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<ResetAuthEvent>((event, emit) => emit(AuthInitial()));
  }

  Future<void> _onRequestOtp(
    RequestOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await apiClient.requestOtp(event.phone);
      emit(OtpSentState());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onVerifyOtp(
    VerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final token = await apiClient.verifyOtp(event.phone, event.code);
      emit(AuthAuthenticated(token: token));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
}
