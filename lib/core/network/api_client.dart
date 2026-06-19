import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../crypto/token_security.dart';
import '../error/app_exceptions.dart';

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
      ),
    );
  }

  Future<void> requestOtp(String phone) async {
    try {
      // استخراج و ارسال هش سخت‌افزاری در مرحله اول
      final deviceHash = await _security.getDeviceHash();
      await _dio.post(
        '/auth/request-otp',
        data: {'mobile': phone, 'hardware_id': deviceHash},
      );
    } on DioException catch (e) {
      log("API Error: ${e.response?.data}", name: 'ApiClient');
      throw ServerException(
        e.response?.data['detail'] ?? "Failed to request OTP",
      );
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  Future<String> verifyOtp(String phone, String code) async {
    try {
      final deviceHash = await _security.getDeviceHash();

      final response = await _dio.post(
        '/auth/verify-otp',
        data: {'mobile': phone, 'code': code, 'hardware_id': deviceHash},
      );

      final token = response.data['access_token'];
      final encryptedToken = await _security.encryptToken(token);
      await _storage.write(key: 'jwt_token', value: encryptedToken);
      return token;
    } on DioException catch (e) {
      log("Verify OTP Error: ${e.response?.data}", name: 'ApiClient');
      throw ServerException(
        e.response?.data['detail'] ?? "Invalid OTP or hardware mismatch",
      );
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  Future<List<dynamic>> fetchCourses() async {
    try {
      final response = await _dio.get('/dashboard/my-courses');
      return response.data is List
          ? response.data
          : (response.data['courses'] ?? []);
    } on DioException catch (e) {
      throw ServerException("Failed to fetch courses: ${e.message}");
    }
  }

  Future<Map<String, dynamic>> fetchVideoKeys(
    String courseId,
    String videoId,
  ) async {
    try {
      final keyResponse = await _dio.get(
        'https://api.devstorage.site/drm/$courseId/vid_$videoId/keys',
      );
      return keyResponse.data;
    } on DioException catch (e) {
      log("DRM Key Error: ${e.response?.data}", name: 'ApiClient');
      throw ServerException(
        e.response?.data['detail'] ?? "Failed to fetch video keys",
      );
    }
  }

  Future<Map<String, dynamic>> fetchCourseDetails(String courseId) async {
    try {
      final response = await _dio.get('/course/$courseId');
      return response.data;
    } on DioException catch (e) {
      throw ServerException("Failed to fetch course details: ${e.message}");
    }
  }
}
