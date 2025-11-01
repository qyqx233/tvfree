import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:tvfree/data/repository/restful.dart';
import 'package:tvfree/domain/model/resource_cache.dart';
import 'package:tvfree/domain/repository/resource.dart';
import 'package:tvfree/domain/signals/signals.dart';
import 'package:tvfree/objectbox.g.dart';

class ResourceRepositoryImpl implements ResourceRepository {
  final Store database;
  final String apiBaseUrl;

  ResourceRepositoryImpl(this.database,
      {this.apiBaseUrl = 'http://192.168.5.28:8000/api/v1'});

  @override
  Future<TvSearchRs> searchTv(String name) async {
    try {
      debugPrint("endpoint=${parseM3U8EndpointSignal.value}");
      final apiService =
          gApiServiceMng.getApiService(parseM3U8EndpointSignal.value);
      final result = await apiService.searchTv({'name': name});

      // 打印返回值用于调试
      // debugPrint('=== searchTv API Response ===');
      // debugPrint('Search query: $name');
      // debugPrint('Response code: ${result.code}');
      // debugPrint('Response message: ${result.msg}');
      // debugPrint('Response data keys: ${result.data.keys.toList()}');
      // result.data.forEach((key, value) {
      //   debugPrint('Data for key $key: ${value.length} items');
      //   if (value.isNotEmpty) {
      //     debugPrint('First item: ${value.first}');
      //   }
      // });
      // debugPrint('=== End of API Response ===');

      // 缓存搜索结果
      // await cacheSearchResult(name, result);

      return result;
    } catch (e) {
      // 如果网络请求失败，尝试返回缓存的结果
      final cachedResult = await getCachedSearchResult(name);
      if (cachedResult != null) {
        return cachedResult;
      }
      rethrow;
    }
  }

  @override
  Future<ParseM3u8Rs> parseM3U8(String url) async {
    try {
      final apiService = gApiServiceMng.getApiService(apiBaseUrl);
      return await apiService.parseM3U8({'url': url});
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<TvSearchData?> getResourceDetails(String m3u8) async {
    // 这里可以实现获取资源详情的逻辑
    // 目前返回null，可以根据需要扩展
    return null;
  }

  @override
  Future<void> cacheSearchResult(String query, TvSearchRs result) async {
    try {
      final box = database.box<ResourceCache>();
      final cache = ResourceCache.fromSearchResult(query, result);
      await box.putAsync(cache);
    } catch (e) {
      // 缓存失败不影响主要功能
    }
  }

  @override
  Future<TvSearchRs?> getCachedSearchResult(String query) async {
    try {
      final box = database.box<ResourceCache>();
      final queryBuilder =
          box.query(ResourceCache_.query.equals(query)).build();
      final cache = queryBuilder.findFirst();
      queryBuilder.close();

      if (cache == null || cache.isExpired()) {
        return null;
      }

      // 将JSON字符串转换为Map，然后使用fromJson创建TvSearchRs对象
      if (cache.resultJson != null) {
        final Map<String, dynamic> jsonMap = jsonDecode(cache.resultJson!);
        return TvSearchRs.fromJson(jsonMap);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final box = database.box<ResourceCache>();
      await box.removeAllAsync();
    } catch (e) {
      // 清除缓存失败不影响主要功能
    }
  }
}
