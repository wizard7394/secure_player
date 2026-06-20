import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc(this.repository) : super(AuthInitial()) {
    on<RequestOtpEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        await repository.requestOtp(event.mobile);
        emit(AuthOtpRequested());
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    on<VerifyOtpEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        final token = await repository.verifyOtp(event.mobile, event.code);
        emit(AuthAuthenticated(token));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });
  }
}
