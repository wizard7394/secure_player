import '../../../../core/network/api_client.dart';

class AuthRepository {
  final ApiClient apiClient;

  AuthRepository(this.apiClient);

  Future<void> requestOtp(String mobile) async {
    await apiClient.requestOtp(mobile);
  }

  Future<String> verifyOtp(String mobile, String code) async {
    return await apiClient.verifyOtp(mobile, code);
  }
}
