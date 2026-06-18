import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/app_exceptions.dart';
import '../../data/dashboard_repository.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object> get props => [];
}

class FetchCoursesEvent extends DashboardEvent {}

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final List<dynamic> courses;

  const DashboardLoaded({required this.courses});

  @override
  List<Object> get props => [courses];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});

  @override
  List<Object> get props => [message];
}

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository dashboardRepository;

  DashboardBloc({required this.dashboardRepository})
    : super(DashboardInitial()) {
    on<FetchCoursesEvent>(_onFetchCourses);
  }

  Future<void> _onFetchCourses(
    FetchCoursesEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final courses = await dashboardRepository.getMyCourses();
      emit(DashboardLoaded(courses: courses));
    } on AppException catch (e) {
      emit(DashboardError(message: e.message));
    } catch (e) {
      emit(const DashboardError(message: "An unexpected error occurred."));
    }
  }
}
