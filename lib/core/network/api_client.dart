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
            final encryptedToken = await _storage.read(key: 'jwt_token');
            if (encryptedToken != null) {
              final token = await _security.decryptToken(encryptedToken);
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          final statusCode = e.response?.statusCode;
          final errorData = e.response?.data?.toString().toUpperCase() ?? '';

          final isKillSwitch =
              statusCode == 403 || errorData.contains('BLOCKED');
          final isUnauthorized = statusCode == 401;

          if (isKillSwitch || isUnauthorized) {
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
      ),
    );
  }

  Future<void> requestOtp(String identifier) async {
    try {
      final deviceHash = await _security.getDeviceHash();
      final specs = await _security.fetchSystemSpecs();
      await _dio.post(
        '/client/auth/request-otp',
        data: {
          'identifier': identifier,
          'hardware_id': deviceHash,
          'system_specs': specs,
        },
      );
    } on DioException catch (e) {
      if (e.error == "ACCESS_REVOKED") {
        throw ServerException("System access revoked.");
      }
      final serverDetail = e.response?.data?['detail'];
      throw ServerException(serverDetail ?? "Net Error: \${e.message}");
    } catch (e) {
      throw ServerException("Sys Error: \$e");
    }
  }

  Future<String> verifyOtp(
    String identifier,
    String codeOrPassword, {
    bool isPassword = false,
  }) async {
    try {
      final deviceHash = await _security.getDeviceHash();
      final specs = await _security.fetchSystemSpecs();

      final Map<String, dynamic> requestData = {
        'identifier': identifier,
        'hardware_id': deviceHash,
        'system_specs': specs,
      };

      if (isPassword) {
        requestData['password'] = codeOrPassword;
      } else {
        requestData['code'] = codeOrPassword;
      }

      final response = await _dio.post(
        '/client/auth/verify-otp',
        data: requestData,
      );

      final token = response.data['access_token'];
      final encryptedToken = await _security.encryptToken(token);
      await _storage.write(key: 'jwt_token', value: encryptedToken);

      return token;
    } on DioException catch (e) {
      if (e.error == "ACCESS_REVOKED") {
        throw ServerException("System access revoked.");
      }
      final serverDetail = e.response?.data?['detail'];
      throw ServerException(serverDetail ?? "Net Error: \${e.message}");
    } catch (e) {
      throw ServerException("Sys Error: \$e");
    }
  }

  Future<List<dynamic>> fetchCourses() async {
    try {
      final response = await _dio.get('/client/course/my-courses');
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
    try {
      final deviceHash = await _security.getDeviceHash();
      final response = await _dio.get(
        'https://api.devstorage.site/drm/$courseId/manifest/$videoId',
        options: Options(headers: {'X-Hardware-Id': deviceHash}),
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        log("FastAPI Validation Error: ${e.response?.data}", name: "DRM_DEBUG");
      }
      if (e.error == "ACCESS_REVOKED") {
        throw ServerException("System access revoked.");
      }
      final serverDetail = e.response?.data?['detail'];
      throw ServerException(
        serverDetail?.toString() ?? "Net Error: ${e.message}",
      );
    } catch (e) {
      throw ServerException("Sys Error: $e");
    }
  }

  Future<Map<String, dynamic>> fetchCourseDetails(String courseId) async {
    final response = await _dio.get('/client/course/view/$courseId');
    return response.data;
  }
}
