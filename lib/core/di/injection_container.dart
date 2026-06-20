import 'package:get_it/get_it.dart';
import 'package:secure_player/features/auth_license/data/auth_repository.dart';
import '../../features/auth_license/presentation/bloc/auth_bloc.dart';
import '../../features/dashboard/data/dashboard_repository.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/dashboard/presentation/bloc/course_detail_bloc.dart';
import '../../features/player/data/domain/repositories/video_stream_repository.dart';
import '../../features/player/data/repositories/video_stream_repository_impl.dart';
import '../../features/player/presentation/bloc/video_player_bloc.dart';
import '../../features/security_overlay/presentation/bloc/watermark_bloc.dart';
import '../network/api_client.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core / Network
  sl.registerLazySingleton(() => ApiClient());

  // Repositories
  sl.registerLazySingleton(() => DashboardRepository());
  sl.registerLazySingleton(() => AuthRepository(sl()));
  sl.registerLazySingleton<VideoStreamRepository>(
    () => VideoStreamRepositoryImpl(apiClient: sl()),
  );

  // BLoCs
  sl.registerFactory(() => AuthBloc(sl()));
  sl.registerFactory(() => DashboardBloc(dashboardRepository: sl()));
  sl.registerFactory(() => CourseDetailBloc(dashboardRepository: sl()));
  sl.registerFactory(() => VideoPlayerBloc(videoStreamRepository: sl()));
  sl.registerFactory(() => WatermarkBloc());
}
