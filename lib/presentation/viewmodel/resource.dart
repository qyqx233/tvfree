import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signals/signals_flutter.dart';
import 'package:tvfree/data/repository/restful.dart';
import 'package:tvfree/domain/usecase/control_device.dart';
import 'package:tvfree/domain/usecase/crud_device.dart';
import 'package:tvfree/domain/signals/signals.dart';

// “剧集-渠道”视图模型结构
class ChannelOption {
  final int channelId;
  final String m3u8;
  final String? url;
  final String? name;
  final int? duration;
  final String? subtitle;

  ChannelOption({
    required this.channelId,
    required this.m3u8,
    this.url,
    this.name,
    this.duration,
    this.subtitle,
  });
}

class EpisodeGroup {
  final int episode;
  final List<ChannelOption> channels;

  EpisodeGroup({required this.episode, required this.channels});
}

class ResourceVM {
  // 单例实例
  static ResourceVM? _instance;

  // 信号状态
  final searchText = signal<String>('');
  final isLoading = signal<bool>(false);
  final searchResults = signal<TvSearchRs?>(null);
  final parseResults = signal<ParseM3u8Rs?>(null);
  // 转换后的"剧集-渠道"结构和选择状态
  final episodes = listSignal<EpisodeGroup>([]);
  final selectedEpisode = signal<int?>(null);
  final selectedChannelId = signal<int?>(null);

  // 存储相关状态
  final storageLoading = signal<bool>(false);
  final storageInfo = signal<List<CaddyFileInfo>?>(null);
  final currentPath = signal<String>('');
  final pathHistory = listSignal<String>(['']);
  final CrudDevice crudDevice;
  final ControlDevice controlDevice;

  // 获取单例实例的工厂构造函数
  factory ResourceVM(CrudDevice crudDevice, ControlDevice controlDevice) {
    _instance ??= ResourceVM._internal(crudDevice, controlDevice);
    return _instance!;
  }

  // 私有构造函数
  ResourceVM._internal(this.crudDevice, this.controlDevice);

  // 搜索影视资源
  Future<void> searchTv(String query) async {
    if (query.isEmpty) return;

    isLoading.value = true;
    try {
      final apiService =
          gApiServiceMng.getApiService(parseM3U8EndpointSignal.value);
      final result = await apiService.searchTv({'name': query});
      searchResults.value = result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('搜索失败: $e');
      }
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // 解析M3U8
  Future<void> parseM3U8(String m3u8Url) async {
    isLoading.value = true;
    try {
      final apiService = gApiServiceMng.getApiService(remoteStorageUrl.value);
      final result = await apiService.parseM3U8({'url': m3u8Url});
      parseResults.value = result;
      // 转换为“剧集-渠道”结构
      final grouped = _groupEpisodesByChannels(result);
      episodes.value = grouped;
      // 默认选中第一集与其第一个渠道
      if (grouped.isNotEmpty) {
        selectedEpisode.value = grouped.first.episode;
        if (grouped.first.channels.isNotEmpty) {
          selectedChannelId.value = grouped.first.channels.first.channelId;
        } else {
          selectedChannelId.value = null;
        }
      } else {
        selectedEpisode.value = null;
        selectedChannelId.value = null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('解析失败json: $e');
      }
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // 清除搜索结果
  void clearSearchResults() {
    searchResults.value = null;
  }

  // 清除解析结果
  void clearParseResults() {
    parseResults.value = null;
    episodes.value = [];
    selectedEpisode.value = null;
    selectedChannelId.value = null;
  }

  // 获取存储信息
  Future<void> getStorageInfo(String path, {int isMedia = 1}) async {
    storageLoading.value = true;
    if (kDebugMode) {}
    try {
      final storageService =
          gApiServiceMng.getStorageApiService(remoteStorageUrl.value);
      final requestPath = "/$path";
      final result = await storageService.getFileInfo(requestPath);
      storageInfo.value = result;
      currentPath.value = path;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('获取存储信息失败: $e');
      }
      rethrow;
    } finally {
      storageLoading.value = false;
    }
  }

  // 进入目录
  void enterDirectory(String dirName) {
    final newPath =
        currentPath.value == '.' ? dirName : '${currentPath.value}/$dirName';
    pathHistory.add(newPath);
    getStorageInfo(newPath);
  }

  // 返回上级目录
  void goBack() {
    if (pathHistory.length > 1) {
      pathHistory.removeLast();
      final previousPath = pathHistory.last;
      currentPath.value = previousPath;
      getStorageInfo(previousPath);
    }
  }

  // 重置所有状态
  void reset() {
    searchText.value = '';
    isLoading.value = false;
    searchResults.value = null;
    parseResults.value = null;
    episodes.value = [];
    selectedEpisode.value = null;
    selectedChannelId.value = null;

    // 重置存储状态
    storageLoading.value = false;
    storageInfo.value = null;
    currentPath.value = '.';
    pathHistory.value = ['.'];
  }

  // 重置单例实例的方法（主要用于测试）
  static void resetInstance() {
    _instance = null;
  }

  // —— 工具与选择方法 ——
  List<ChannelOption> getChannelsForEpisode(int episode) {
    try {
      return episodes.value.firstWhere((e) => e.episode == episode).channels;
    } catch (_) {
      return [];
    }
  }

  void selectEpisode(int episode) {
    selectedEpisode.value = episode;
    final channels = getChannelsForEpisode(episode);
    selectedChannelId.value =
        channels.isNotEmpty ? channels.first.channelId : null;
  }

  void selectChannel(int channelId) {
    selectedChannelId.value = channelId;
  }

  String? getSelectedM3u8() {
    final ep = selectedEpisode.value;
    if (ep == null) return null;
    final channels = getChannelsForEpisode(ep);
    if (channels.isEmpty) return null;
    final cid = selectedChannelId.value;
    if (cid == null) return channels.first.m3u8;
    try {
      return channels.firstWhere((c) => c.channelId == cid).m3u8;
    } catch (_) {
      return channels.first.m3u8;
    }
  }

  // 将解析结果转换为“剧集-渠道”结构
  List<EpisodeGroup> _groupEpisodesByChannels(ParseM3u8Rs rs) {
    final Map<int, List<ChannelOption>> byEpisode = {};
    rs.data.forEach((channelId, items) {
      for (final item in items) {
        final ep = item.episode ?? -1;
        if (!byEpisode.containsKey(ep)) {
          byEpisode[ep] = [];
        }
        byEpisode[ep]!.add(ChannelOption(
          channelId: channelId,
          m3u8: item.m3u8,
          url: item.url,
          name: item.name,
          duration: item.duration,
          subtitle: item.subtitle,
        ));
      }
    });

    final groups = byEpisode.entries
        .map((e) => EpisodeGroup(episode: e.key, channels: e.value))
        .toList();
    groups.sort((a, b) => a.episode.compareTo(b.episode));
    return groups;
  }
}
