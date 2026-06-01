import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';

abstract class WatermarkEvent {}

class FetchWatermarkData extends WatermarkEvent {
  final String jwtToken;
  FetchWatermarkData(this.jwtToken);
}

abstract class WatermarkState {}

class WatermarkInitial extends WatermarkState {}

class WatermarkLoaded extends WatermarkState {
  final String text;
  WatermarkLoaded(this.text);
}

class WatermarkBloc extends Bloc<WatermarkEvent, WatermarkState> {
  final Dio _dio = Dio();

  WatermarkBloc() : super(WatermarkInitial()) {
    on<FetchWatermarkData>((event, emit) async {
      try {
        final response = await _dio.get(
          'http://127.0.0.1:8000/api/v1/user/watermark',
          options: Options(
            headers: {'Authorization': 'Bearer ${event.jwtToken}'},
          ),
        );

        if (response.statusCode == 200) {
          emit(WatermarkLoaded(response.data['watermark_text']));
        } else {
          emit(WatermarkLoaded("NABEGHEHA - SECURITY"));
        }
      } catch (e) {
        emit(WatermarkLoaded("NABEGHEHA - OFFLINE"));
      }
    });
  }
}
