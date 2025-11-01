import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signals/signals_flutter.dart';
import 'package:tvfree/data/repository/restful.dart'; // 导入 restful.dart
import 'package:tvfree/domain/model/m3u8.dart';
import 'package:tvfree/domain/usecase/control_device.dart';
import 'package:tvfree/domain/usecase/crud_device.dart';
import 'package:tvfree/domain/usecase/m3u8_parser.dart';

class M3u8ParserVM {
  // 单例实例
  static M3u8ParserVM? _instance;
  final M3u8ParserService _m3u8ParserService;
  final CrudDevice crudDevice;
  final ControlDevice controlDevice;
  final isLoading = signal<bool>(false);
  final parseResults = listSignal<String>([]);
  final isBatchMode = signal<bool>(false);
  final startEpisode = signal<int>(1);
  final endEpisode = signal<int>(1);
  final batchProgress = signal<String>('');
  final currentUrl = signal<String>('');
  M3u8Parser? _activeParser;
  StreamSubscription<List<M3u8Parser>>? _parserSubscription;

  // API 服务实例

  // 获取单例实例的工厂构造函数
  factory M3u8ParserVM(M3u8ParserService repo, CrudDevice crudDevice,
      ControlDevice controlDevice) {
    _instance ??= M3u8ParserVM._internal(repo, crudDevice, controlDevice);
    return _instance!;
  }

  // 私有构造函数
  M3u8ParserVM._internal(
      this._m3u8ParserService, this.crudDevice, this.controlDevice) {
    // 初始化活跃解析器
    _loadActiveParser();
    // 监听解析器变化
    _setupParserWatcher();
  }

  Future<void> _loadActiveParser() async {
    try {
      final allParsers = await _m3u8ParserService.getAll();
      if (allParsers.isNotEmpty) {
        _activeParser = allParsers.firstWhere(
          (parser) => parser.isActive,
          orElse: () => allParsers.first,
        );
      } else {
        _activeParser = null;
      }
    } catch (e) {
      _activeParser = null;
    }
  }

  // 模拟数据存储

  Future<List<String>> parseM3u8(String url) async {
    // 如果有活跃的解析器，使用它的端点进行解析
    if (_activeParser == null) {
      throw Exception('没有活跃的解析器');
    }

    try {
      isLoading.value = true;
      parseResults.value = [];
      final parser = _activeParser!;
      final Map<String, dynamic> requestBody = {
        'url': url,
      };
      if (parser.sk != null && parser.sk!.isNotEmpty) {
        requestBody['sk'] = parser.sk;
      }
      if (kDebugMode) {
        debugPrint('使用解析器: ${parser.url}, 请求体: $requestBody');
      }
      final response = await gApiServiceMng
          .getApiService(_activeParser!.url!)
          .parseM3U8(requestBody);
      if (response.code != 200) {
        throw Exception('解析失败: ${response.msg}');
      }
      List<String> results = [];
      for (var entry in response.data.entries) {
        for (var item in entry.value) {
          results.add(item.m3u8);
        }
      }
      parseResults.value = results;
      return results;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('解析M3U8失败: $e');
      }
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  // 批量解析方法
  Future<void> batchParseM3u8(
      String baseUrl, int startEpisode, int endEpisode) async {
    if (_activeParser == null) {
      throw Exception('没有活跃的解析器');
    }

    if (startEpisode > endEpisode) {
      throw Exception('起始集数不能大于终止集数');
    }

    try {
      isLoading.value = true;
      parseResults.value = []; // 批量解析不展示结果，清空之前的结果
      batchProgress.value = '准备批量解析...';

      final parser = _activeParser!;
      int successCount = 0;
      int failCount = 0;
      try {
        // 构建当前集数的URL
        final Map<String, dynamic> requestBody = {
          'url': baseUrl,
          'start': startEpisode,
          'end': endEpisode,
        };
        if (parser.sk != null && parser.sk!.isNotEmpty) {
          requestBody['sk'] = parser.sk;
        }
        final response = await gApiServiceMng
            .getApiService(parser.url!)
            .parseM3U8(requestBody);
        if (response.code != 200) {
          throw Exception('解析失败: ${response.msg}');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint("提交失败: $e");
        }
      }

      // for (int episode = startEpisode; episode <= endEpisode; episode++) {
      //   batchProgress.value = '正在解析第 $episode 集...';

      //   try {
      //     // 构建当前集数的URL
      //     final currentUrl = _buildEpisodeUrl(baseUrl, episode);

      //     final Map<String, dynamic> requestBody = {
      //       'url': currentUrl,
      //     };
      //     if (parser.sk != null && parser.sk!.isNotEmpty) {
      //       requestBody['sk'] = parser.sk;
      //     }

      //     final response = await gApiServiceMng
      //         .getApiService(parser.url!)
      //         .parseM3U8(requestBody);

      //     if (response.code == 200) {
      //       successCount++;
      //     } else {
      //       failCount++;
      //     }
      //   } catch (e) {
      //     failCount++;
      //     if (kDebugMode) {
      //       debugPrint('解析第 $episode 集失败: $e');
      //     }
      //   }
      // }

      batchProgress.value = '批量解析完成！成功: $successCount，失败: $failCount';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('批量解析M3U8失败: $e');
      }
      batchProgress.value = '批量解析失败: $e';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // 获取当前活跃的解析器
  M3u8Parser? get activeParser => _activeParser;

  // 刷新活跃解析器
  Future<void> refreshActiveParser() async {
    await _loadActiveParser();
  }

  // 设置解析器监听
  void _setupParserWatcher() {
    _parserSubscription = _m3u8ParserService.watchAll().listen((parsers) {
      // 当解析器列表发生变化时，重新加载活跃解析器
      if (kDebugMode) {
        debugPrint('解析器列表发生变化，重新加载活跃解析器');
      }
      _loadActiveParser();
    });
  }

  // 重置单例实例的方法（主要用于测试）
  static void reset() {
    _instance?._parserSubscription?.cancel();
    _instance = null;
  }

  // 销毁资源
  void dispose() {
    _parserSubscription?.cancel();
  }
}
