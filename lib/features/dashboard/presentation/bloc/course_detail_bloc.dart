import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';

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
  final List<dynamic> sections;
  const CourseDetailLoaded({required this.sections});
  @override
  List<Object> get props => [sections];
}

class CourseDetailError extends CourseDetailState {
  final String message;
  const CourseDetailError({required this.message});
  @override
  List<Object> get props => [message];
}

class CourseDetailBloc extends Bloc<CourseDetailEvent, CourseDetailState> {
  final ApiClient apiClient;

  CourseDetailBloc({required this.apiClient}) : super(CourseDetailInitial()) {
    on<FetchCourseContentEvent>(_onFetchContent);
  }

  Future<void> _onFetchContent(
    FetchCourseContentEvent event,
    Emitter<CourseDetailState> emit,
  ) async {
    emit(CourseDetailLoading());
    try {
      final sections = await apiClient.fetchCourseDetails(event.courseId);
      emit(CourseDetailLoaded(sections: sections));
    } catch (e) {
      emit(CourseDetailError(message: e.toString()));
    }
  }
}
