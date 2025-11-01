import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signals/signals_flutter.dart';
import 'package:tvfree/domain/model/kv.dart';
import 'package:tvfree/domain/model/m3u8.dart';
import 'package:tvfree/domain/repository/kvs.dart';
import 'package:tvfree/domain/signals/signals.dart';
import 'package:tvfree/domain/usecase/m3u8_parser.dart';

class SettingsVM {
  static SettingsVM? _instance;
  final KvRepository _kvRepository;
  final M3u8ParserService _m3u8ParserService;
  final isLoading = signal<bool>(false);
  final parsers = listSignal<M3u8Parser>([]);
  late final FlutterComputed<M3u8Parser?> activeParser;
  StreamSubscription<List<M3u8Parser>>? _parserSubscription;

  factory SettingsVM(
      KvRepository kvRepository, M3u8ParserService m3u8ParserService) {
    _instance ??= SettingsVM._internal(kvRepository, m3u8ParserService);
    return _instance!;
  }
  SettingsVM._internal(this._kvRepository, this._m3u8ParserService) {
    activeParser = computed(() {
      try {
        return parsers.firstWhere((parser) => parser.isActive);
      } catch (e) {
        return null;
      }
    });
    _loadSettings();
    _setupParserWatcher();
  }

  void _setupParserWatcher() {
    _parserSubscription = _m3u8ParserService.watchAll().listen((parserList) {
      parsers.value = parserList;
    });
  }

  // 加载设置
  Future<void> _loadSettings() async {
    try {
      isLoading.value = true;

      // 加载远程存储配置
      final url = await _kvRepository.getByKey('remote_storage_url');
      final apiKey = await _kvRepository.getByKey('remote_storage_api_key');
      final enabled = await _kvRepository.getByKey('remote_storage_enabled');
      if (kDebugMode) {
        debugPrint('加载设置: url=$url, apiKey=$apiKey, enabled=$enabled');
      }
      remoteStorageUrl.value = url ?? '';
      remoteStorageApiKey.value = apiKey ?? '';
      remoteStorageEnabled.value = enabled == 'true';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('加载设置失败: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveRemoteEnabled(bool enabled) async {
    try {
      isLoading.value = true;
      remoteStorageEnabled.value = enabled;
      await _kvRepository
          .add(Kv(key: 'remote_storage_enabled', value: enabled.toString()));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('保存远程存储启用状态失败: $e');
      }
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // 保存远程存储配置
  Future<void> saveRemoteStorageSettings() async {
    try {
      isLoading.value = true;

      // 验证URL格式
      if (remoteStorageUrl.value.isNotEmpty) {
        final uri = Uri.tryParse(remoteStorageUrl.value);
        if (uri == null || !uri.hasScheme || (!uri.scheme.startsWith('http'))) {
          throw Exception('请输入有效的HTTP/HTTPS URL');
        }
      }

      // 保存设置到数据库
      await _kvRepository
          .add(Kv(key: 'remote_storage_url', value: remoteStorageUrl.value));
      await _kvRepository.add(
          Kv(key: 'remote_storage_api_key', value: remoteStorageApiKey.value));
      await _kvRepository.add(Kv(
          key: 'remote_storage_enabled',
          value: remoteStorageEnabled.value.toString()));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('保存远程存储设置失败: $e');
      }
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // 测试远程存储连接
  Future<bool> testRemoteStorageConnection() async {
    if (remoteStorageUrl.value.isEmpty) {
      throw Exception('请先配置远程存储URL');
    }

    try {
      // 这里可以添加实际的HTTP请求测试连接
      // 暂时返回true作为占位符
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('测试远程存储连接失败: $e');
      }
      return false;
    }
  }

  // 重置远程存储设置
  Future<void> resetRemoteStorageSettings() async {
    try {
      isLoading.value = true;

      remoteStorageUrl.value = '';
      remoteStorageApiKey.value = '';
      remoteStorageEnabled.value = false;

      await _kvRepository.removeByKey('remote_storage_url');
      await _kvRepository.removeByKey('remote_storage_api_key');
      await _kvRepository.removeByKey('remote_storage_enabled');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('重置远程存储设置失败: $e');
      }
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // 刷新设置
  Future<void> refresh() async {
    await _loadSettings();
  }

  // M3U8 解析器管理方法
  Future<void> addM3u8Parser(M3u8Parser parser) async {
    try {
      await _m3u8ParserService.add(parser);
      // 不再需要手动刷新，watchAll 会自动检测变化
    } catch (e, stacktrace) {
      if (kDebugMode) {
        debugPrint('添加解析器失败: $e, $stacktrace');
      }
      rethrow;
    }
  }

  Future<void> removeM3u8Parser(M3u8Parser parser) async {
    try {
      await _m3u8ParserService.remove(parser);
      // 不再需要手动刷新，watchAll 会自动检测变化
    } catch (e) {
      if (kDebugMode) {
        debugPrint('删除解析器失败: $e');
      }
      rethrow;
    }
  }

  Future<void> updateM3u8Parser(M3u8Parser parser) async {
    try {
      await _m3u8ParserService.update(parser);
      // 不再需要手动刷新，watchAll 会自动检测变化
    } catch (e) {
      if (kDebugMode) {
        debugPrint('更新解析器失败: $e');
      }
      rethrow;
    }
  }

  Future<List<M3u8Parser>> getAllParsers() async {
    return _m3u8ParserService.getAll();
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
