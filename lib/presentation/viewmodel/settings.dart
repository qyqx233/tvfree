import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signals/signals_flutter.dart';
import 'package:tvfree/domain/model/kv.dart';
import 'package:tvfree/domain/repository/kvs.dart';
import 'package:tvfree/domain/signals/signal.dart';

class SettingsVM {
  // 单例实例
  static SettingsVM? _instance;
  final KvRepository _kvRepository;

  // 远程存储配置

  final isLoading = signal<bool>(false);

  // 获取单例实例的工厂构造函数
  factory SettingsVM(KvRepository kvRepository) {
    _instance ??= SettingsVM._internal(kvRepository);
    return _instance!;
  }

  // 私有构造函数
  SettingsVM._internal(this._kvRepository) {
    _loadSettings();
  }

  // 加载设置
  Future<void> _loadSettings() async {
    try {
      isLoading.value = true;

      // 加载远程存储配置
      final url = await _kvRepository.getByKey('remote_storage_url');
      final apiKey = await _kvRepository.getByKey('remote_storage_api_key');
      final enabled = await _kvRepository.getByKey('remote_storage_enabled');

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

  // 重置单例实例的方法（主要用于测试）
  static void reset() {
    _instance = null;
  }
}
