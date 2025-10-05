import 'dart:convert';
import 'package:objectbox/objectbox.dart';
import 'package:tvfree/data/repository/restful.dart';

@Entity()
class ResourceCache {
  @Id()
  int id = 0;

  String? query;
  String? resultJson;
  DateTime? createdAt;
  DateTime? expiresAt;

  ResourceCache({
    this.id = 0,
    this.query,
    this.resultJson,
    required this.createdAt,
    required this.expiresAt,
  });

  factory ResourceCache.fromSearchResult(String query, TvSearchRs result,
      {Duration cacheDuration = const Duration(hours: 24)}) {
    return ResourceCache(
      query: query,
      resultJson: result.toJson().toString(),
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(cacheDuration),
    );
  }

  TvSearchRs? toSearchResult() {
    if (resultJson == null || resultJson!.isEmpty) return null;

    try {
      // 将JSON字符串转换为Map，然后使用fromJson创建TvSearchRs对象
      final Map<String, dynamic> jsonMap = jsonDecode(resultJson!);
      return TvSearchRs.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  bool isExpired() {
    if (expiresAt == null) return true;
    return DateTime.now().isAfter(expiresAt!);
  }
}
