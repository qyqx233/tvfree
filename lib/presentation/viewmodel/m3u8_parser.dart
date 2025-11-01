import 'package:flutter/foundation.dart';
import 'package:signals/signals_flutter.dart';
import 'package:tvfree/data/repository/restful.dart'; // 导入 restful.dart
import 'package:tvfree/domain/signals/signals.dart';
import 'package:tvfree/domain/usecase/control_device.dart';
import 'package:tvfree/domain/usecase/crud_device.dart';
import 'package:tvfree/domain/usecase/m3u8_parser.dart';

class M3u8ParserVM {
  // 单例实例
  static M3u8ParserVM? _instance;
  final CrudDevice crudDevice;
  final ControlDevice controlDevice;
  final isLoading = signal<bool>(false);
  final parseResults = listSignal<String>([]);
  final batchParseResults = signal<Map<int, List<ParseM3u8Data>>>({});
  final isBatchMode = signal<bool>(false);
  final startEpisode = signal<int>(1);
  final endEpisode = signal<int>(1);
  final batchProgress = signal<String>('');
  final currentUrl = signal<String>('');

  // API 服务实例

  // 获取单例实例的工厂构造函数
  factory M3u8ParserVM(CrudDevice crudDevice, ControlDevice controlDevice) {
    _instance ??= M3u8ParserVM._internal(crudDevice, controlDevice);
    return _instance!;
  }

  // 私有构造函数
  M3u8ParserVM._internal(this.crudDevice, this.controlDevice) {
    // 不再需要初始化活跃解析器和监听解析器变化
    // 这些逻辑已经移动到TvFreeApp中
  }

  // 模拟数据存储

  Future<List<String>> parseM3u8(String url) async {
    // 使用信号中的解析器端点进行解析
    final parserUrl = parseM3U8EndpointSignal.value;
    final parserSk = m3u8SkSignal.value;

    if (parserUrl.isEmpty) {
      throw Exception('没有活跃的解析器');
    }

    try {
      isLoading.value = true;
      parseResults.value = [];
      final Map<String, dynamic> requestBody = {
        'url': url,
      };
      if (parserSk != null && parserSk.isNotEmpty) {
        requestBody['sk'] = parserSk;
      }
      if (kDebugMode) {
        debugPrint('使用解析器: $parserUrl, 请求体: $requestBody');
      }
      final response =
          await gApiServiceMng.getApiService(parserUrl).parseM3U8(requestBody);
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
    // 使用信号中的解析器端点进行解析
    final parserUrl = parseM3U8EndpointSignal.value;
    final parserSk = m3u8SkSignal.value;

    if (parserUrl.isEmpty) {
      throw Exception('没有活跃的解析器');
    }

    if (startEpisode > endEpisode) {
      throw Exception('起始集数不能大于终止集数');
    }

    try {
      isLoading.value = true;
      parseResults.value = []; // 清空单集解析结果
      batchParseResults.value = {}; // 清空之前的批量解析结果
      batchProgress.value = '准备批量解析...';

      int successCount = 0;
      int failCount = 0;
      Map<int, List<ParseM3u8Data>> results = {};

      try {
        // 构建当前集数的URL
        final Map<String, dynamic> requestBody = {
          'url': baseUrl,
          'start': startEpisode,
          'end': endEpisode,
        };
        if (parserSk != null && parserSk.isNotEmpty) {
          requestBody['sk'] = parserSk;
        }
        final response = await gApiServiceMng
            .getApiService(parserUrl)
            .parseM3U8(requestBody);
        debugPrint('response=${response.code} ${response.data}');
        if (response.code != 200) {
          throw Exception('解析失败: ${response.msg}');
        }

        // 保存批量解析结果
        results = response.data;
        batchParseResults.value = results;

        // 计算成功和失败的集数
        for (var entry in results.entries) {
          if (entry.value.isNotEmpty) {
            successCount++;
          } else {
            failCount++;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint("提交失败: $e");
        }
        batchProgress.value = '批量解析失败: $e';
        rethrow;
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

  // 获取当前活跃的解析器URL
  String get activeParserUrl => parseM3U8EndpointSignal.value;

  // 刷新活跃解析器（现在由TvFreeApp处理）
  Future<void> refreshActiveParser() async {
    // 不再需要在这里实现，因为逻辑已经移动到TvFreeApp
  }

  // 重置单例实例的方法（主要用于测试）
  static void reset() {
    _instance = null;
  }

  // 销毁资源
  void dispose() {
    // 不再需要取消订阅，因为订阅已经移动到TvFreeApp
  }
}
