import 'package:get_it/get_it.dart';
import '../../features/auth_license/presentation/bloc/auth_bloc.dart';
import '../../features/dashboard/data/dashboard_repository.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/dashboard/presentation/bloc/course_detail_bloc.dart';
import '../../features/player/presentation/bloc/video_player_bloc.dart';
import '../../features/security_overlay/presentation/bloc/watermark_bloc.dart';
import '../network/api_client.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerLazySingleton(() => ApiClient());
  sl.registerLazySingleton(() => DashboardRepository());

  sl.registerFactory(() => AuthBloc(apiClient: sl()));
  sl.registerFactory(() => DashboardBloc(apiClient: sl()));

  sl.registerFactory(() => CourseDetailBloc(sl()));

  sl.registerFactory(() => VideoPlayerBloc());
  sl.registerFactory(() => WatermarkBloc());
}
