import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:retrofit/retrofit.dart';
import 'package:tvfree/internal/util/stream.dart';

part 'restful.g.dart';

@JsonSerializable()
class ParseM3u8Data {
  final String m3u8;
  final int? episode;
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

// 定义 TvSearchRs 类
@JsonSerializable()
class TvSearchRs {
  final int code;
  final String msg;
  final Map<String, Map<String, List<TvSearchData>>> data;

  TvSearchRs({
    required this.code,
    required this.msg,
    required this.data,
  });

  // JSON 序列化和反序列化方法
  factory TvSearchRs.fromJson(Map<String, dynamic> json) =>
      _$TvSearchRsFromJson(json);

  Map<String, dynamic> toJson() => _$TvSearchRsToJson(this);
}

// 定义 TvSearchData 类
@JsonSerializable()
class TvSearchData {
  final String m3u8;

  TvSearchData({
    required this.m3u8,
  });

  // JSON 序列化和反序列化方法
  factory TvSearchData.fromJson(Map<String, dynamic> json) =>
      _$TvSearchDataFromJson(json);

  Map<String, dynamic> toJson() => _$TvSearchDataToJson(this);
}

// 定义 FileInfoResponse 类
@JsonSerializable()
class FileInfoResponse {
  final String err;
  final String md5;
  final List<String>? dirs;
  final List<String>? files;

  FileInfoResponse({
    required this.err,
    required this.md5,
    this.dirs,
    this.files,
  });

  // JSON 序列化和反序列化方法
  factory FileInfoResponse.fromJson(Map<String, dynamic> json) =>
      _$FileInfoResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FileInfoResponseToJson(this);
}

@RestApi(baseUrl: "http://api.com/api/v1")
abstract class ApiService {
  factory ApiService(Dio dio, {String? baseUrl}) = _ApiService;

  @POST('/tv/parsem3u8')
  Future<ParseM3u8Rs> parseM3U8(
    @Body() Map<String, dynamic> body, // 请求体: {"url": "http://example.com"}
  );

  @POST('/tv/search')
  Future<TvSearchRs> searchTv(
    @Body() Map<String, dynamic> body, // 请求体: {"name": "悬崖"}
  );
}

@RestApi(baseUrl: "http://localhost:9999")
abstract class StorageApiService {
  factory StorageApiService(Dio dio, {String? baseUrl}) = _StorageApiService;

  @GET('/fileinfo')
  Future<FileInfoResponse> getFileInfo(
    @Query('q') String path,
    @Query('isMedia') int isMedia,
  );
}

final Dio gDio = Dio();

class ApiServiceMng {
  final Map<String, ApiService> _apiServiceMap = {};
  final Map<String, StorageApiService> _storageApiServiceMap = {};

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

  StorageApiService getStorageApiService(String baseURL) {
    StorageApiService? storageApiService;
    if (_storageApiServiceMap.containsKey(baseURL)) {
      return _storageApiServiceMap[baseURL]!;
    }
    storageApiService = StorageApiService(gDio, baseUrl: baseURL);
    synchronized(() {
      _storageApiServiceMap[baseURL] = storageApiService!;
    });
    return storageApiService;
  }
}

final gApiServiceMng = ApiServiceMng();
