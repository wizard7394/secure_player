import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../crypto/token_security.dart';
import '../error/app_exceptions.dart';
import '../../src/rust/api/simple.dart';

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

          if (isKillSwitch) {
            log('SECURITY ALERT: Kill Switch Triggered.', name: 'ApiClient');
            await _storage.deleteAll();
            clearDecryptionKeys();

            return handler.reject(
              DioException(
                requestOptions: e.requestOptions,
                error: "ACCESS_REVOKED",
              ),
            );
          }

          if (isUnauthorized) {
            log('AUTH ALERT: Token expired or missing.', name: 'ApiClient');
            await _storage.deleteAll();

            return handler.reject(
              DioException(
                requestOptions: e.requestOptions,
                error: "UNAUTHORIZED",
              ),
            );
          }

          return handler.next(e);
        },
      ),
    );
  }

  Future<void> requestOtp(String phone) async {
    try {
      final deviceHash = await _security.getDeviceHash();
      final specs = await _security.fetchSystemSpecs();
      await _dio.post(
        '/auth/request-otp',
        data: {
          'mobile': phone,
          'hardware_id': deviceHash,
          'system_specs': specs,
        },
      );
    } on DioException catch (e) {
      if (e.error == "ACCESS_REVOKED") {
        throw ServerException("System access revoked.");
      }
      throw ServerException(e.response?.data['detail'] ?? "Request Failed");
    }
  }

  Future<String> verifyOtp(String phone, String code) async {
    try {
      final deviceHash = await _security.getDeviceHash();
      final specs = await _security.fetchSystemSpecs();

      final response = await _dio.post(
        '/auth/verify-otp',
        data: {
          'mobile': phone,
          'code': code,
          'hardware_id': deviceHash,
          'system_specs': specs,
        },
      );

      final token = response.data['access_token'];
      final encryptedToken = await _security.encryptToken(token);
      await _storage.write(key: 'jwt_token', value: encryptedToken);
      return token;
    } on DioException catch (e) {
      if (e.error == "ACCESS_REVOKED") {
        throw ServerException("System access revoked.");
      }
      throw ServerException(
        e.response?.data['detail'] ?? "Verification Failed",
      );
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
