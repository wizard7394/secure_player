import '../../../../core/network/api_client.dart';
import '../../../../core/error/app_exceptions.dart';
import '../domain/repositories/video_stream_repository.dart';

class VideoStreamRepositoryImpl implements VideoStreamRepository {
  final ApiClient apiClient;

  VideoStreamRepositoryImpl({required this.apiClient});

  @override
  Future<Map<String, dynamic>> getVideoKeys(
    String courseId,
    String videoId,
  ) async {
    try {
      return await apiClient.fetchVideoKeys(courseId, videoId);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException("Failed to fetch DRM keys: $e");
    }
  }
}
