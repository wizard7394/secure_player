import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../crypto/token_security.dart';
import '../error/app_exceptions.dart';
import '../utils/globals.dart';
import '../../src/rust/api/simple.dart';
import '../../features/auth_license/presentation/screens/login_screen.dart';

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TokenSecurity _security = TokenSecurity();

  Dio get dio => _dio;

  ApiClient()
    : _dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.devstorage.site/api/v1',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          log(
            "[ApiClient] 🌐 OUTGOING REQUEST: [${options.method}] ${options.path}",
            name: 'Network',
          );
          if (!options.headers.containsKey('Authorization')) {
            log(
              "[ApiClient] ⏳ Missing Auth header, checking secure storage...",
              name: 'Network',
            );
            final encryptedToken = await _storage.read(key: 'jwt_token');
            if (encryptedToken != null) {
              final token = await _security.decryptToken(encryptedToken);
              if (token != null) {
                log(
                  "[ApiClient] ✅ Token decrypted and attached to header.",
                  name: 'Network',
                );
                options.headers['Authorization'] = 'Bearer $token';
              } else {
                log(
                  "[ApiClient] ⚠️ Token decryption returned null.",
                  name: 'Network',
                );
              }
            } else {
              log("[ApiClient] ⚠️ No token found in storage.", name: 'Network');
            }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          final statusCode = e.response?.statusCode;
          final errorData = e.response?.data?.toString().toUpperCase() ?? '';
          log(
            "[ApiClient] ❌ INCOMING ERROR: [${e.requestOptions.method}] ${e.requestOptions.path} | Status: $statusCode",
            name: 'Network',
          );

          final isKillSwitch =
              statusCode == 403 || errorData.contains('BLOCKED');
          final isUnauthorized = statusCode == 401;

          if (isKillSwitch || isUnauthorized) {
            if (isKillSwitch) {
              log(
                '[ApiClient] 🚨 SECURITY ALERT: Kill Switch Triggered.',
                name: 'Network',
              );
            } else {
              log(
                '[ApiClient] ⚠️ AUTH ALERT: Token expired or missing.',
                name: 'Network',
              );
            }

            await _storage.deleteAll();
            clearDecryptionKeys();

            if (globalNavigatorKey.currentContext != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(
                  globalNavigatorKey.currentContext!,
                ).showSnackBar(
                  SnackBar(
                    content: Text(
                      isKillSwitch
                          ? "System access revoked."
                          : "Session expired. Please login again.",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );

                globalNavigatorKey.currentState?.pushAndRemoveUntil(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const LoginScreen(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                  (route) => false,
                );
              });
            }

            return handler.reject(
              DioException(
                requestOptions: e.requestOptions,
                error: isKillSwitch ? "ACCESS_REVOKED" : "UNAUTHORIZED",
              ),
            );
          }

          return handler.next(e);
        },
        onResponse: (response, handler) {
          log(
            "[ApiClient] 🟢 INCOMING RESPONSE: [${response.requestOptions.method}] ${response.requestOptions.path} | Status: ${response.statusCode}",
            name: 'Network',
          );
          return handler.next(response);
        },
      ),
    );
  }

  Future<void> requestOtp(String phone) async {
    log("[ApiClient] 🚀 Initiating requestOtp...", name: 'Network');
    try {
      final deviceHash = await _security.getDeviceHash();
      final specs = await _security.fetchSystemSpecs();
      log("[ApiClient] 📡 Sending POST to /auth/request-otp", name: 'Network');
      await _dio.post(
        '/auth/request-otp',
        data: {
          'mobile': phone,
          'hardware_id': deviceHash,
          'system_specs': specs,
        },
      );
      log("[ApiClient] ✅ requestOtp completed.", name: 'Network');
    } on DioException catch (e) {
      log("[ApiClient] ❌ requestOtp DioException: ${e.error}", name: 'Network');
      if (e.error == "ACCESS_REVOKED") {
        throw ServerException("System access revoked.");
      }
      throw ServerException(e.response?.data['detail'] ?? "Request Failed");
    } catch (e) {
      log("[ApiClient] ❌ requestOtp Unknown Error: $e", name: 'Network');
      throw ServerException("Unknown Error");
    }
  }

  Future<String> verifyOtp(String phone, String code) async {
    log("[ApiClient] 🚀 Initiating verifyOtp...", name: 'Network');
    try {
      final deviceHash = await _security.getDeviceHash();
      final specs = await _security.fetchSystemSpecs();

      log("[ApiClient] 📡 Sending POST to /auth/verify-otp", name: 'Network');
      final response = await _dio.post(
        '/auth/verify-otp',
        data: {
          'mobile': phone,
          'code': code,
          'hardware_id': deviceHash,
          'system_specs': specs,
        },
      );

      log(
        "[ApiClient] ✅ verifyOtp API returned success. Extracting token...",
        name: 'Network',
      );
      final token = response.data['access_token'];
      final encryptedToken = await _security.encryptToken(token);
      log(
        "[ApiClient] 💾 Writing encrypted token to Secure Storage...",
        name: 'Network',
      );
      await _storage.write(key: 'jwt_token', value: encryptedToken);
      log("[ApiClient] 🎉 verifyOtp completely finished.", name: 'Network');
      return token;
    } on DioException catch (e) {
      log("[ApiClient] ❌ verifyOtp DioException: ${e.error}", name: 'Network');
      if (e.error == "ACCESS_REVOKED") {
        throw ServerException("System access revoked.");
      }
      throw ServerException(
        e.response?.data['detail'] ?? "Verification Failed",
      );
    } catch (e) {
      log("[ApiClient] ❌ verifyOtp Unknown Error: $e", name: 'Network');
      throw ServerException("Unknown Error");
    }
  }

  Future<List<dynamic>> fetchCourses() async {
    try {
      final response = await _dio.get('/dashboard/my-courses');
      return response.data is List
          ? response.data
          : (response.data['courses'] ?? []);
    } on DioException catch (e) {
      if (e.error == "ACCESS_REVOKED") {
        throw ServerException("System access revoked.");
      }
      if (e.error == "UNAUTHORIZED") {
        throw ServerException("Session expired. Please login again.");
      }
      throw ServerException("Failed to fetch courses.");
    }
  }

  Future<Map<String, dynamic>> fetchVideoKeys(
    String courseId,
    String videoId,
  ) async {
    final response = await _dio.get(
      'https://api.devstorage.site/drm/$courseId/vid_$videoId/keys',
    );
    return response.data;
  }

  Future<Map<String, dynamic>> fetchCourseDetails(String courseId) async {
    final response = await _dio.get('/course/$courseId');
    return response.data;
  }
}
