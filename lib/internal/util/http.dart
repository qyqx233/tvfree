import 'package:tvfree/internal/util/dio_helper.dart';

class Http {
  static Future<String?> fetchString(String url) async {
    try {
      final response = await DioClient.instance.dio.get(url);
      return response.data as String?;
    } catch (e) {
      return null;
    }
  }
}
