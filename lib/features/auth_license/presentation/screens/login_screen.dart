import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  Timer? _timer;
  int _secondsRemaining = 120;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 120;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
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
      padding: const EdgeInsets.all(40.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is OtpSentState) {
            _codeController.clear();
            if (_timer == null || !_timer!.isActive) {
              _startTimer();
            }
          } else if (state is AuthInitial) {
            _timer?.cancel();
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getCleanErrorMessage(state.message),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFFD32F2F),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                margin: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                elevation: 10,
              ),
            );
          } else if (state is AuthAuthenticated) {
            _timer?.cancel();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          }
        },
        builder: (context, state) {
          bool isCodeMode = state is OtpSentState || state is AuthError;

          // بررسی اینکه آیا دکمه باید روشن باشد یا خاموش
          bool isButtonDisabled = state is AuthLoading;
          if (isCodeMode && _codeController.text.length != 7) {
            isButtonDisabled = true;
          } else if (!isCodeMode && _phoneController.text.length < 10) {
            isButtonDisabled = true;
          }

          return Stack(
            children: [
              if (isCodeMode)
                Positioned(
                  top: -10,
                  left: -10,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white54,
                    ),
                    onPressed: () {
                      context.read<AuthBloc>().add(ResetAuthEvent());
                    },
                  ),
                ),

              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      isCodeMode ? "VERIFICATION" : "SECURE LOGIN",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      isCodeMode
                          ? "Enter the 7-digit code sent to your device"
                          : "Enter your registered mobile number",
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),

                  TextField(
                    controller: isCodeMode ? _codeController : _phoneController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(isCodeMode ? 7 : 15),
                    ],
                    onChanged: (value) {
                      // آپدیت کردن استیت برای ارزیابی مجدد فعال/غیرفعال بودن دکمه
                      setState(() {});
                    },
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 2.0,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF141414),
                      hintText: isCodeMode ? "- - - - - - -" : "09...",
                      hintStyle: const TextStyle(
                        color: Colors.white12,
                        letterSpacing: 4.0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(
                          color: Color(0xFF00E676),
                          width: 1.0,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  if (isCodeMode)
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Center(
                        child: _secondsRemaining > 0
                            ? Text(
                                _formatTime(_secondsRemaining),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 15,
                                  fontFamily: 'monospace',
                                ),
                              )
                            : TextButton(
                                onPressed: state is AuthLoading
                                    ? null
                                    : () {
                                        context.read<AuthBloc>().add(
                                          RequestOtpEvent(
                                            phone: _phoneController.text,
                                          ),
                                        );
                                      },
                                child: const Text(
                                  "RESEND OTP",
                                  style: TextStyle(
                                    color: Color(0xFF00E676),
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    )
                  else
                    const SizedBox(height: 30),

                  if (isCodeMode) const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: const Color(0xFF141414),
                        disabledForegroundColor: Colors.white24,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isButtonDisabled
                          ? null
                          : () {
                              if (isCodeMode) {
                                context.read<AuthBloc>().add(
                                  VerifyOtpEvent(
                                    phone: _phoneController.text,
                                    code: _codeController.text,
                                  ),
                                );
                              } else {
                                context.read<AuthBloc>().add(
                                  RequestOtpEvent(phone: _phoneController.text),
                                );
                              }
                            },
                      child: state is AuthLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white54,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              isCodeMode ? "VERIFY" : "CONTINUE",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
