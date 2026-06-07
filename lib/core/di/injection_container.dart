import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import '../../features/auth_license/presentation/bloc/auth_bloc.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/dashboard/presentation/bloc/course_detail_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core
  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  // Blocs
  sl.registerFactory<AuthBloc>(() => AuthBloc(apiClient: sl()));

  sl.registerFactory<DashboardBloc>(() => DashboardBloc(apiClient: sl()));

  sl.registerFactory<CourseDetailBloc>(() => CourseDetailBloc(apiClient: sl()));
}
