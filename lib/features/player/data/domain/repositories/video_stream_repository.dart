abstract class VideoStreamRepository {
  Future<Map<String, dynamic>> getVideoKeys(String courseId, String videoId);
}
