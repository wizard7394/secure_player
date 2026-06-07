import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';

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
  final ApiClient apiClient;

  DashboardBloc({required this.apiClient}) : super(DashboardInitial()) {
    on<FetchCoursesEvent>(_onFetchCourses);
  }

  Future<void> _onFetchCourses(
    FetchCoursesEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final courses = await apiClient.fetchCourses();
      emit(DashboardLoaded(courses: courses));
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }
}
