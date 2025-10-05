import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:tvfree/presentation/viewmodel/settings.dart';
import 'package:tvfree/domain/signals/signal.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key, required this.viewModel});
  final SettingsVM viewModel;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _urlController = TextEditingController();
  final _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _urlController.text = remoteStorageUrl.value;
    _apiKeyController.text = remoteStorageApiKey.value;
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _saveSettings() async {
    try {
      // 更新view model中的值
      remoteStorageUrl.value = _urlController.text;
      remoteStorageApiKey.value = _apiKeyController.text;

      // 保存设置
      await widget.viewModel.saveRemoteStorageSettings();
      _showSuccessSnackBar('设置已保存');
    } catch (e) {
      _showErrorSnackBar('保存设置失败: $e');
    }
  }

  Future<void> _testConnection() async {
    try {
      // 更新view model中的值
      remoteStorageUrl.value = _urlController.text;
      remoteStorageApiKey.value = _apiKeyController.text;

      final success = await widget.viewModel.testRemoteStorageConnection();
      if (success) {
        _showSuccessSnackBar('连接测试成功');
      } else {
        _showErrorSnackBar('连接测试失败');
      }
    } catch (e) {
      _showErrorSnackBar('连接测试失败: $e');
    }
  }

  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置设置'),
        content: const Text('确定要重置所有远程存储设置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('重置', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.viewModel.resetRemoteStorageSettings();
        _urlController.clear();
        _apiKeyController.clear();
        _showSuccessSnackBar('设置已重置');
      } catch (e) {
        _showErrorSnackBar('重置设置失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await widget.viewModel.refresh();
              _urlController.text = remoteStorageUrl.value;
              _apiKeyController.text = remoteStorageApiKey.value;
            },
            tooltip: '刷新设置',
          ),
        ],
      ),
      body: Watch((context) {
        if (widget.viewModel.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 远程存储配置区域
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.cloud_queue, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            '远程存储配置',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Watch((context) => Switch(
                                value: remoteStorageEnabled.value,
                                onChanged: (value) {
                                  remoteStorageEnabled.value = value;
                                },
                              )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '配置远程HTTP服务器用于存储和同步数据',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: '服务器URL',
                          hintText: 'http://example.com/api',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                        ),
                        keyboardType: TextInputType.url,
                        onChanged: (value) {
                          remoteStorageUrl.value = value;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _apiKeyController,
                        decoration: const InputDecoration(
                          labelText: 'API密钥 (可选)',
                          hintText: '输入API密钥',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.vpn_key),
                        ),
                        obscureText: true,
                        onChanged: (value) {
                          remoteStorageApiKey.value = value;
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.save),
                              label: const Text('保存设置'),
                              onPressed: widget.viewModel.isLoading.value
                                  ? null
                                  : _saveSettings,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.wifi_tethering),
                              label: const Text('测试连接'),
                              onPressed: widget.viewModel.isLoading.value
                                  ? null
                                  : _testConnection,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.restore, color: Colors.red),
                          label: const Text(
                            '重置设置',
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: widget.viewModel.isLoading.value
                              ? null
                              : _resetSettings,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 其他设置区域
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info, size: 24),
                          SizedBox(width: 8),
                          Text(
                            '关于',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('应用版本'),
                        subtitle: Text('1.0.0'),
                      ),
                      const ListTile(
                        leading: Icon(Icons.description),
                        title: Text('使用说明'),
                        subtitle: Text('配置远程存储后，数据将自动同步到云端'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }
}
