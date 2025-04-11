import 'package:dio/dio.dart';

class Http {
  static Future<String?> fetchString(String url) async {
    final dio = Dio();
    try {
      final response = await dio.get(url);
      return response.data as String?;
    } catch (e) {
      return null;
    }
  }
}
