// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restful.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParseM3u8Data _$ParseM3u8DataFromJson(Map<String, dynamic> json) =>
    ParseM3u8Data(
      episode: (json['episode'] as num).toInt(),
      m3u8: json['m3u8'] as String,
      url: json['url'] as String? ?? '',
      name: json['name'] as String? ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      subtitle: json['subtitle'] as String? ?? '',
    );

Map<String, dynamic> _$ParseM3u8DataToJson(ParseM3u8Data instance) =>
    <String, dynamic>{
      'episode': instance.episode,
      'm3u8': instance.m3u8,
      'url': instance.url,
      'name': instance.name,
      'duration': instance.duration,
      'subtitle': instance.subtitle,
    };

ParseM3u8Rs _$ParseM3u8RsFromJson(Map<String, dynamic> json) => ParseM3u8Rs(
      code: (json['code'] as num).toInt(),
      msg: json['msg'] as String,
      data: (json['data'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            int.parse(k),
            (e as List<dynamic>)
                .map((e) => ParseM3u8Data.fromJson(e as Map<String, dynamic>))
                .toList()),
      ),
    );

Map<String, dynamic> _$ParseM3u8RsToJson(ParseM3u8Rs instance) =>
    <String, dynamic>{
      'code': instance.code,
      'msg': instance.msg,
      'data': instance.data.map((k, e) => MapEntry(k.toString(), e)),
    };

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers,unused_element,unnecessary_string_interpolations

class _ApiService implements ApiService {
  _ApiService(
    this._dio, {
    this.baseUrl,
    this.errorLogger,
  }) {
    baseUrl ??= 'http://api.com/api/v1';
  }

  final Dio _dio;

  String? baseUrl;

  final ParseErrorLogger? errorLogger;

  @override
  Future<ParseM3u8Rs> parseM3U8(Map<String, dynamic> body) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body);
    final _options = _setStreamType<ParseM3u8Rs>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
    )
        .compose(
          _dio.options,
          '/tv/parsem3u8',
          queryParameters: queryParameters,
          data: _data,
        )
        .copyWith(
            baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        )));
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late ParseM3u8Rs _value;
    try {
      _value = ParseM3u8Rs.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options);
      rethrow;
    }
    return _value;
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }

  String _combineBaseUrls(
    String dioBaseUrl,
    String? baseUrl,
  ) {
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return dioBaseUrl;
    }

    final url = Uri.parse(baseUrl);

    if (url.isAbsolute) {
      return url.toString();
    }

    return Uri.parse(dioBaseUrl).resolveUri(url).toString();
  }
}
