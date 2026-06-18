import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/app_exceptions.dart';
import '../../data/dashboard_repository.dart';

abstract class CourseDetailEvent extends Equatable {
  const CourseDetailEvent();
  @override
  List<Object> get props => [];
}

class FetchCourseContentEvent extends CourseDetailEvent {
  final String courseId;
  const FetchCourseContentEvent(this.courseId);
  @override
  List<Object> get props => [courseId];
}

abstract class CourseDetailState extends Equatable {
  const CourseDetailState();
  @override
  List<Object> get props => [];
}

class CourseDetailInitial extends CourseDetailState {}

class CourseDetailLoading extends CourseDetailState {}

class CourseDetailLoaded extends CourseDetailState {
  final Map<String, dynamic> courseData;

  const CourseDetailLoaded({required this.courseData});

  @override
  List<Object> get props => [courseData];
}

class CourseDetailError extends CourseDetailState {
  final String message;
  const CourseDetailError({required this.message});
  @override
  List<Object> get props => [message];
}

class CourseDetailBloc extends Bloc<CourseDetailEvent, CourseDetailState> {
  final DashboardRepository dashboardRepository;

  CourseDetailBloc({required this.dashboardRepository})
    : super(CourseDetailInitial()) {
    on<FetchCourseContentEvent>(_onFetchContent);
  }

  Future<void> _onFetchContent(
    FetchCourseContentEvent event,
    Emitter<CourseDetailState> emit,
  ) async {
    emit(CourseDetailLoading());
    try {
      final courseData = await dashboardRepository.getCourseDetails(
        event.courseId,
      );
      emit(CourseDetailLoaded(courseData: courseData));
    } on AppException catch (e) {
      emit(CourseDetailError(message: e.message));
    } catch (e) {
      emit(const CourseDetailError(message: "An unexpected error occurred."));
    }
  }
}
