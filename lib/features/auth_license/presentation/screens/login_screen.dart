import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:secure_player/features/auth_license/presentation/bloc/auth_bloc.dart';
import 'package:secure_player/features/dashboard/presentation/screens/dashboard_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF050505),
      body: Center(child: SingleChildScrollView(child: AuthFormContainer())),
    );
  }
}

class AuthFormContainer extends StatefulWidget {
  const AuthFormContainer({super.key});

  @override
  State<AuthFormContainer> createState() => _AuthFormContainerState();
}

class _AuthFormContainerState extends State<AuthFormContainer> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  Timer? _timer;

  @override
  void dispose() {
    _mobileController.dispose();
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _getCleanErrorMessage(String rawMessage) {
    final lowerRaw = rawMessage.toLowerCase();
    if (lowerRaw.contains('invalid')) return 'Invalid Verification Code!';
    if (lowerRaw.contains('expired')) {
      return 'Code expired. Please request a new one.';
    }
    if (lowerRaw.contains('not found')) {
      return 'No account found for this number.';
    }
    return 'Authentication Failed. Try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
      ),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _getCleanErrorMessage(state.message),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: Colors.red.shade900,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is AuthAuthenticated) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          }
        },
        builder: (context, state) {
          final bool isCodeMode = state is OtpSentState || state is AuthError;
          final bool isLoading = state is AuthLoading;

          bool isButtonDisabled = isLoading;
          if (isCodeMode && _codeController.text.length != 6) {
            isButtonDisabled = true;
          }
          if (!isCodeMode && _mobileController.text.length < 10) {
            isButtonDisabled = true;
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (isCodeMode)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white70,
                        ),
                        onPressed: () =>
                            context.read<AuthBloc>().add(ResetAuthEvent()),
                      ),
                    ),
                  Text(
                    isCodeMode ? "VERIFICATION" : "SECURE LOGIN",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              TextField(
                controller: isCodeMode ? _codeController : _mobileController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  letterSpacing: 2.0,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF141414),
                  hintText: isCodeMode ? "- - - - - -" : "09...",
                  hintStyle: const TextStyle(color: Colors.white24),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black, // متن مشکی برای خوانایی عالی
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isButtonDisabled
                      ? null
                      : () {
                          if (isCodeMode) {
                            context.read<AuthBloc>().add(
                              VerifyOtpEvent(
                                mobile: _mobileController.text,
                                code: _codeController.text,
                              ),
                            );
                          } else {
                            context.read<AuthBloc>().add(
                              RequestOtpEvent(mobile: _mobileController.text),
                            );
                          }
                        },
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2.5,
                        )
                      : Text(
                          isCodeMode ? "VERIFY" : "CONTINUE",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
