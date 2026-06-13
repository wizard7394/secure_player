import 'package:dio/dio.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';

class DashboardRepository {
  final Dio _dio;

  DashboardRepository() : _dio = sl<ApiClient>().dio;

  Future<Map<String, dynamic>> getCourseDetails(int courseId) async {
    try {
      final response = await _dio.get('/course/$courseId');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to load course structure');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Network error');
    }
  }
}
