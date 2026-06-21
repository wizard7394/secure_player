import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc(this.repository) : super(AuthInitial()) {
    on<RequestOtpEvent>((event, emit) async {
      log(
        "[AuthBloc] 📥 Received RequestOtpEvent for mobile: ${event.mobile}",
        name: 'BLoC',
      );
      emit(AuthLoading());
      try {
        log("[AuthBloc] ⏳ Calling repository.requestOtp...", name: 'BLoC');
        await repository.requestOtp(event.mobile);
        log(
          "[AuthBloc] ✅ OTP Requested successfully. Emitting AuthOtpRequested.",
          name: 'BLoC',
        );
        emit(AuthOtpRequested());
      } catch (e) {
        log("[AuthBloc] ❌ Error in RequestOtpEvent: $e", name: 'BLoC');
        emit(AuthError(e.toString()));
      }
    });

    on<VerifyOtpEvent>((event, emit) async {
      log(
        "[AuthBloc] 📥 Received VerifyOtpEvent for code: ${event.code}",
        name: 'BLoC',
      );
      emit(AuthLoading());
      try {
        log("[AuthBloc] ⏳ Calling repository.verifyOtp...", name: 'BLoC');
        final token = await repository.verifyOtp(event.mobile, event.code);
        log(
          "[AuthBloc] ✅ OTP Verified successfully. Emitting AuthAuthenticated.",
          name: 'BLoC',
        );
        emit(AuthAuthenticated(token));
      } catch (e) {
        log("[AuthBloc] ❌ Error in VerifyOtpEvent: $e", name: 'BLoC');
        emit(AuthError(e.toString()));
      }
    });
  }
}
