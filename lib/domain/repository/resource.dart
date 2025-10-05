import 'package:tvfree/data/repository/restful.dart';

abstract class ResourceRepository {
  // 搜索影视资源
  Future<TvSearchRs> searchTv(String name);

  // 解析M3U8资源
  Future<ParseM3u8Rs> parseM3U8(String url);

  // 获取资源详情
  Future<TvSearchData?> getResourceDetails(String m3u8);

  // 缓存搜索结果
  Future<void> cacheSearchResult(String query, TvSearchRs result);

  // 获取缓存的搜索结果
  Future<TvSearchRs?> getCachedSearchResult(String query);

  // 清除缓存
  Future<void> clearCache();
}
