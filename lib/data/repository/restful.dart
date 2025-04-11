import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:retrofit/retrofit.dart';
import 'package:tvfree/internal/util/stream.dart';

part 'restful.g.dart';

@JsonSerializable()
class ParseM3u8Data {
  final int episode;
  final String m3u8;
  final String? url;
  final String? name;
  final int? duration;
  final String? subtitle;

  ParseM3u8Data({
    required this.episode,
    required this.m3u8,
    this.url = '',
    this.name = '',
    this.duration = 0,
    this.subtitle = '',
  });

  // JSON 序列化和反序列化方法
  factory ParseM3u8Data.fromJson(Map<String, dynamic> json) =>
      _$ParseM3u8DataFromJson(json);

  Map<String, dynamic> toJson() => _$ParseM3u8DataToJson(this);
}

// 定义 ParseM3u8Rs 类
@JsonSerializable()
class ParseM3u8Rs {
  final int code;
  final String msg;
  final Map<int, List<ParseM3u8Data>> data;

  ParseM3u8Rs({
    required this.code,
    required this.msg,
    required this.data,
  });

  // JSON 序列化和反序列化方法
  factory ParseM3u8Rs.fromJson(Map<String, dynamic> json) =>
      _$ParseM3u8RsFromJson(json);

  Map<String, dynamic> toJson() => _$ParseM3u8RsToJson(this);
}

@RestApi(baseUrl: "http://api.com/api/v1")
abstract class ApiService {
  factory ApiService(Dio dio, {String? baseUrl}) = _ApiService;

  @POST('/tv/parsem3u8')
  Future<ParseM3u8Rs> parseM3U8(
    @Body() Map<String, dynamic> body, // 请求体: {"url": "http://example.com"}
  );
}

class ApiServiceMng {
  final Map<String, ApiService> _apiServiceMap = {};
  final Dio gDio = Dio();
  ApiService getApiService(String baseURL) {
    ApiService? apiService;
    if (_apiServiceMap.containsKey(baseURL)) {
      return _apiServiceMap[baseURL]!;
    }
    apiService = ApiService(gDio, baseUrl: baseURL);
    synchronized(() {
      _apiServiceMap[baseURL] = apiService!;
    });
    return apiService;
  }
}

final gApiServiceMng = ApiServiceMng();
