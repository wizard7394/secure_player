import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/error/app_exceptions.dart';

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository() : _apiClient = sl<ApiClient>();

  Future<List<dynamic>> getMyCourses() async {
    try {
      return await _apiClient.fetchCourses();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException("Failed to load user courses: $e");
    }
  }

  Future<Map<String, dynamic>> getCourseDetails(dynamic courseId) async {
    try {
      return await _apiClient.fetchCourseDetails(courseId.toString());
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException("Failed to load course structure: $e");
    }
  }
}
