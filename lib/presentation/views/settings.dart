import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:tvfree/presentation/viewmodel/settings.dart';
import 'package:tvfree/domain/model/m3u8.dart';
import 'package:tvfree/domain/signals/signals.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key, required this.viewModel});
  final SettingsVM viewModel;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _urlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  late final List<Function> _subscriptions;

  @override
  void initState() {
    super.initState();
    _urlController.text = remoteStorageUrl.value;
    _apiKeyController.text = remoteStorageApiKey.value;

    // 监听信号变化，更新控制器
    _subscriptions = [
      remoteStorageUrl.subscribe((_) {
        if (_urlController.text != remoteStorageUrl.value) {
          _urlController.text = remoteStorageUrl.value;
        }
      }),
      remoteStorageApiKey.subscribe((_) {
        if (_apiKeyController.text != remoteStorageApiKey.value) {
          _apiKeyController.text = remoteStorageApiKey.value;
        }
      }),
    ];
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

  Future<void> _addParser() async {
    final result = await _showParserDialog();
    if (result != null) {
      try {
        await widget.viewModel.addM3u8Parser(result);
        _showSuccessSnackBar('解析器添加成功');
      } catch (e) {
        _showErrorSnackBar('添加解析器失败: $e');
      }
    }
  }

  Future<void> _editParser(M3u8Parser parser) async {
    final result = await _showParserDialog(parser: parser);
    if (result != null) {
      try {
        await widget.viewModel.updateM3u8Parser(result);
        _showSuccessSnackBar('解析器更新成功');
      } catch (e) {
        _showErrorSnackBar('更新解析器失败: $e');
      }
    }
  }

  Future<void> _deleteParser(M3u8Parser parser) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除解析器'),
        content: Text('确定要删除解析器 "${parser.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.viewModel.removeM3u8Parser(parser);
        _showSuccessSnackBar('解析器删除成功');
      } catch (e) {
        _showErrorSnackBar('删除解析器失败: $e');
      }
    }
  }

  Future<M3u8Parser?> _showParserDialog({M3u8Parser? parser}) async {
    final nameController = TextEditingController(text: parser?.name);
    final urlController = TextEditingController(text: parser?.url);
    final skController = TextEditingController(text: parser?.sk);
    final isActive = signal<bool>(parser?.isActive ?? false);

    return showDialog<M3u8Parser?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${parser == null ? '添加' : '编辑'}解析器'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '名称',
                  hintText: '输入解析器名称',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: '解析端点URL',
                  hintText: '输入解析端点URL',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: skController,
                decoration: const InputDecoration(
                  labelText: '密钥(可选)',
                  hintText: '输入密钥(如果需要)',
                ),
              ),
              const SizedBox(height: 16),
              Watch((context) => CheckboxListTile(
                    title: const Text('设为活跃'),
                    value: isActive.value,
                    onChanged: (value) => isActive.value = value ?? false,
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isEmpty || urlController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('名称和URL不能为空')),
                );
                return;
              }

              final newParser = M3u8Parser(
                id: parser?.id ?? 0,
                name: nameController.text,
                url: urlController.text,
                sk: skController.text.isEmpty ? null : skController.text,
                isActive: isActive.value,
              );

              Navigator.of(context).pop(newParser);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _setActiveParser(M3u8Parser parser) async {
    try {
      final updatedParser = parser.copyWith(isActive: !parser.isActive);
      await widget.viewModel.updateM3u8Parser(updatedParser);
      _showSuccessSnackBar(parser.isActive ? '已取消活跃状态' : '已设为活跃解析器');
    } catch (e) {
      _showErrorSnackBar('更新解析器状态失败: $e');
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
                                  widget.viewModel.saveRemoteEnabled(value);
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

              // M3U8 解析器配置区域
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.dns, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'M3U8 解析器配置',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () async {
                              // 手动触发一次解析器列表刷新
                              final parsers =
                                  await widget.viewModel.getAllParsers();
                              // 由于我们使用 watchAll，这里只是获取最新数据
                              _showSuccessSnackBar('解析器列表已刷新');
                            },
                            tooltip: '刷新解析器列表',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '配置用于解析视频流的M3U8解析服务器',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: widget.viewModel.parsers.isEmpty
                            ? const Center(child: Text('暂无解析器，请添加'))
                            : ListView.builder(
                                itemCount: widget.viewModel.parsers.length,
                                itemBuilder: (context, index) {
                                  final parser =
                                      widget.viewModel.parsers[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.dns,
                                        color: parser.isActive
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                      title: Text(
                                        parser.name ?? '未命名解析器',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(parser.url ?? ''),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // 设为活跃按钮
                                          IconButton(
                                            icon: Icon(
                                              parser.isActive
                                                  ? Icons.check_circle
                                                  : Icons
                                                      .radio_button_unchecked,
                                              color: parser.isActive
                                                  ? Colors.green
                                                  : Colors.grey,
                                            ),
                                            tooltip: parser.isActive
                                                ? '当前活跃'
                                                : '设为活跃',
                                            onPressed: () =>
                                                _setActiveParser(parser),
                                          ),
                                          // 编辑按钮
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            tooltip: '编辑',
                                            onPressed: () =>
                                                _editParser(parser),
                                          ),
                                          // 删除按钮
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                            ),
                                            tooltip: '删除',
                                            onPressed: () =>
                                                _deleteParser(parser),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addParser,
        tooltip: '添加解析器',
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    // 取消订阅
    for (final subscription in _subscriptions) {
      subscription();
    }

    // 释放控制器
    _urlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }
}
