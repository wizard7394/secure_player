import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AuthBloc>(),
      child: const LoginView(),
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool isCodeMode = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1A1A1A)),
          ),
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                final errorMessage = state.message
                    .replaceAll('Exception: ', '')
                    .replaceAll('ServerException: ', '')
                    .replaceAll('Server Error: ', '');

                // Prevent duplicate error display since global interceptor handles kill switch
                if (errorMessage.toLowerCase().contains('revoked')) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      errorMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              } else if (state is AuthOtpRequested) {
                setState(() {
                  isCodeMode = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "OTP code sent via SMS",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Color(0xFF00E676),
                  ),
                );
              } else if (state is AuthAuthenticated) {
                Navigator.of(context).pushReplacementNamed('/dashboard');
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoading;

              bool isButtonDisabled = isLoading;
              if (isCodeMode && _codeController.text.length != 6) {
                isButtonDisabled = true;
              }
              if (!isCodeMode && _mobileController.text.length < 10) {
                isButtonDisabled = true;
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DRM SECURE PLAYER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (!isCodeMode) ...[
                    const Text(
                      'Mobile Number',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _mobileController,
                      style: const TextStyle(
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (val) => setState(() {}),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0A0A0A),
                        hintText: "09...",
                        hintStyle: const TextStyle(color: Colors.white24),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Verification Code',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _codeController,
                      style: const TextStyle(
                        color: Colors.white,
                        letterSpacing: 8,
                        fontSize: 20,
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      onChanged: (val) => setState(() {}),
                      decoration: InputDecoration(
                        counterText: "",
                        filled: true,
                        fillColor: const Color(0xFF0A0A0A),
                        hintText: "- - - - - -",
                        hintStyle: const TextStyle(
                          color: Colors.white24,
                          letterSpacing: 2,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: const Color(
                          0xFF00E676,
                        ).withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isButtonDisabled
                          ? null
                          : () {
                              if (!isCodeMode) {
                                context.read<AuthBloc>().add(
                                  RequestOtpEvent(_mobileController.text),
                                );
                              } else {
                                context.read<AuthBloc>().add(
                                  VerifyOtpEvent(
                                    _mobileController.text,
                                    _codeController.text,
                                  ),
                                );
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isCodeMode ? 'VERIFY' : 'CONTINUE',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                    ),
                  ),
                  if (isCodeMode) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                setState(() {
                                  isCodeMode = false;
                                  _codeController.clear();
                                });
                              },
                        child: const Text(
                          'Change Mobile Number',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
