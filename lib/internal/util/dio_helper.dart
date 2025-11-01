import 'package:dio/dio.dart';

class DioClient {
  static final Dio _dio = Dio(
    BaseOptions(
      contentType: Headers.jsonContentType,
    ),
  );

  DioClient._() {
    _dio.options.headers['Accept'] = 'application/json';
  }

  static final instance = DioClient._();

  Dio get dio => _dio;
}
