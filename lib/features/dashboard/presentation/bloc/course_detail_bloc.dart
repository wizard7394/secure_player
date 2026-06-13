import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/dashboard_repository.dart';

abstract class CourseDetailEvent {}

class FetchCourseDetail extends CourseDetailEvent {
  final int courseId;
  FetchCourseDetail(this.courseId);
}

abstract class CourseDetailState {}

class CourseDetailInitial extends CourseDetailState {}

class CourseDetailLoading extends CourseDetailState {}

class CourseDetailLoaded extends CourseDetailState {
  final Map<String, dynamic> courseData;
  CourseDetailLoaded(this.courseData);
}

class CourseDetailError extends CourseDetailState {
  final String message;
  CourseDetailError(this.message);
}

class CourseDetailBloc extends Bloc<CourseDetailEvent, CourseDetailState> {
  final DashboardRepository repository;

  CourseDetailBloc(this.repository) : super(CourseDetailInitial()) {
    on<FetchCourseDetail>((event, emit) async {
      emit(CourseDetailLoading());
      try {
        final data = await repository.getCourseDetails(event.courseId);
        emit(CourseDetailLoaded(data));
      } catch (e) {
        emit(CourseDetailError(e.toString().replaceAll('Exception: ', '')));
      }
    });
  }
}
