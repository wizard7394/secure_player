import 'package:flutter_bloc/flutter_bloc.dart';

abstract class DashboardEvent {}

class FetchCourses extends DashboardEvent {}

abstract class DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final List<Map<String, dynamic>> courses;
  DashboardLoaded(this.courses);
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardLoading()) {
    on<FetchCourses>((event, emit) async {
      emit(DashboardLoading());

      // شبیه‌سازی تاخیر شبکه برای ارتباط با سرور
      await Future.delayed(const Duration(milliseconds: 1500));

      // حالت اول: تستی برای وقتی که دوره ای وجود نداره (برای تست این خط رو از کامنت در بیار و خط پایینی رو کامنت کن)
      emit(DashboardLoaded([]));

      // حالت دوم: تستی برای نمایش لیست دوره‌ها
      // emit(
      //   DashboardLoaded([
      //     {
      //       "id": "1",
      //       "title": "Advanced Linux & Security",
      //       "progress": 45.0,
      //       "image": "LINUX_THUMBNAIL",
      //     },
      //     {
      //       "id": "2",
      //       "title": "Flutter Architecture Masterclass",
      //       "progress": 12.0,
      //       "image": "FLUTTER_THUMBNAIL",
      //     },
      //   ]),
      // );
    });
  }
}
