import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../crypto/token_security.dart';

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
      await _dio.post('/auth/request-otp', data: {'phone_number': phone});
    } on DioException catch (e) {
      print("DEBUG: API Error: ${e.response?.data}");
      rethrow;
    }
  }

  Future<String> verifyOtp(String phone, String code) async {
    final response = await _dio.post(
      '/auth/verify-otp',
      data: {'phone_number': phone, 'code': code},
    );

    final token = response.data['access_token'];
    final encryptedToken = await _security.encryptToken(token);
    await _storage.write(key: 'jwt_token', value: encryptedToken);
    return token;
  }

  Future<List<dynamic>> fetchCourses() async {
    final response = await _dio.get('/dashboard/my-courses');
    return response.data['courses'];
  }

  Future<Map<String, dynamic>> fetchVideoKeys(
    String courseId,
    String licenseKey,
  ) async {
    final deviceHash = await _security.getDeviceHash();

    final authResponse = await _dio.post(
      '/auth/hardware',
      data: {
        'license_key': licenseKey,
        'hardware_hash': deviceHash,
        'platform': Platform.operatingSystem,
      },
    );

    final hwToken = authResponse.data['payload']['access_token'];

    final keyResponse = await _dio.get(
      'https://api.devstorage.site/hls/$courseId/vid_1/keys',
      options: Options(headers: {'Authorization': 'Bearer $hwToken'}),
    );

    return keyResponse.data;
  }

  Future<List<dynamic>> fetchCourseDetails(String courseId) async {
    final response = await _dio.get('/dashboard/course-content/$courseId');
    return response.data['sections'];
  }
}
