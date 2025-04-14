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
  final sc = StreamController<List<M3u8Parser>>.broadcast();
  final M3u8ParserService _repo;
  final CrudDevice crudDevice;
  final ControlDevice controlDevice;
  final parsers = listSignal<M3u8Parser>([]);
  late final _connectParsers = connect(parsers);
  late final FlutterComputed<M3u8Parser?> activeParser;
  final isLoading = signal<bool>(false);
  final currentUrl = signal<String>('');
  final parseResults = listSignal<String>([]);

  // API 服务实例

  // 获取单例实例的工厂构造函数
  factory M3u8ParserVM(M3u8ParserService repo, CrudDevice crudDevice,
      ControlDevice controlDevice) {
    _instance ??= M3u8ParserVM._internal(repo, crudDevice, controlDevice);
    return _instance!;
  }

  // 私有构造函数
  M3u8ParserVM._internal(this._repo, this.crudDevice, this.controlDevice) {
    _connectParsers << sc.stream;
    activeParser = computed(() {
      try {
        return parsers.firstWhere((parser) => parser.isActive);
      } catch (e) {
        return null;
      }
    });
    getAll().then((parsers_) {
      parsers.value = parsers_;
    });
  }

  // 模拟数据存储

  Future<List<String>> parseM3u8(String url) async {
    // 如果有活跃的解析器，使用它的端点进行解析
    if (activeParser.value == null) {
      throw Exception('没有活跃的解析器');
    }

    try {
      isLoading.value = true;
      parseResults.value = [];
      final parser = activeParser.value!;
      final Map<String, dynamic> requestBody = {
        'url': url,
      };
      if (parser.sk != null && parser.sk!.isNotEmpty) {
        requestBody['sk'] = parser.sk;
      }
      final response = await gApiServiceMng
          .getApiService(activeParser.value!.url!)
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

  Future<void> refresh() async {
    sc.sink.add(await getAll());
  }

  Future<void> addM3u8Parser(M3u8Parser parser) async {
    try {
      _repo.add(parser);
      await refresh();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('添加解析器失败: $e');
      }
      rethrow;
    }
  }

  Future<void> removeM3u8Parser(M3u8Parser parser) async {
    try {
      await _repo.remove(parser);
      await refresh();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('删除解析器失败: $e');
      }
      rethrow;
    }
  }

  Future<void> updateM3u8Parser(M3u8Parser parser) async {
    try {
      await _repo.update(parser);
      await refresh();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('更新解析器失败: $e');
      }
      rethrow;
    }
  }

  Future<List<M3u8Parser>> getAll() async {
    // 模拟从数据库加载
    return _repo.getAll();
  }

  // 获取当前活跃的解析器
  // M3u8Parser? get activeParser => activeParser.value;

  // 重置单例实例的方法（主要用于测试）
  static void reset() {
    _instance = null;
  }
}
