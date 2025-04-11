import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:tvfree/domain/model/m3u8.dart';
import 'package:tvfree/presentation/viewmodel/m3u8_parser.dart';

class M3u8ParserView extends StatefulWidget {
  const M3u8ParserView({super.key, required this.viewModel});
  final M3u8ParserVM viewModel;

  @override
  State<M3u8ParserView> createState() => _M3u8ParserViewState();
}

class _M3u8ParserViewState extends State<M3u8ParserView> {
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.viewModel.currentUrl.value;
  }

  Future<void> _loadParsers() async {
    try {
      await widget.viewModel.getAll();
    } catch (e) {
      _showErrorSnackBar('加载解析器失败: $e');
    } finally {}
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _parseM3u8() async {
    if (widget.viewModel.currentUrl.value.isEmpty) {
      _showErrorSnackBar('请输入要解析的 M3U8 地址');
      return;
    }

    try {
      final results =
          await widget.viewModel.parseM3u8(widget.viewModel.currentUrl.value);
      widget.viewModel.parseResults.value = results;
    } catch (e) {
      _showErrorSnackBar('解析失败: $e');
    } finally {}
  }

  Future<void> _addParser() async {
    final result = await _showParserDialog();
    if (result != null) {
      try {
        await widget.viewModel.addM3u8Parser(result);
      } catch (e) {
        _showErrorSnackBar('添加解析器失败: $e');
      } finally {}
    }
  }

  Future<void> _editParser(M3u8Parser parser) async {
    final result = await _showParserDialog(parser: parser);
    if (result != null) {
      try {
        await widget.viewModel.updateM3u8Parser(result);
      } catch (e) {
        _showErrorSnackBar('更新解析器失败: $e');
      } finally {}
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
      } catch (e) {
        _showErrorSnackBar('删除解析器失败: $e');
      } finally {}
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('M3U8解析器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadParsers,
            tooltip: '刷新解析服务器列表',
          ),
        ],
      ),
      body: Watch((context) {
        // if (widget.viewModel.isLoading.value) {
        //   return const Center(child: CircularProgressIndicator());
        // }

        return Column(
          children: [
            // M3U8 URL输入和解析区域
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'URL',
                      hintText: '输入要解析视频的网址',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) =>
                        widget.viewModel.currentUrl.value = value,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.search),
                          label: const Text('解析'),
                          onPressed: widget.viewModel.isLoading.value
                              ? null
                              : _parseM3u8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 解析结果区域
            if (widget.viewModel.parseResults.isNotEmpty)
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        '解析结果:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: widget.viewModel.parseResults.length,
                        itemBuilder: (context, index) {
                          final url = widget.viewModel.parseResults[index];
                          return ListTile(
                            title: Text(url),
                            trailing: IconButton(
                              icon: const Icon(Icons.cast),
                              onPressed: () async {
                                debugPrint('投屏: $url');
                                final device = await widget.viewModel.crudDevice
                                    .getConnectedDevice();
                                if (device == null) {
                                  if (!context.mounted) return;
                                  _showErrorSnackBar('未连接设备');
                                  return;
                                }
                                await widget.viewModel.controlDevice
                                    .castScreen(url);
                                // final result = await widget.viewModel
                                //    .crudDevice.playUrl(device, url);
                              },
                              tooltip: '投屏',
                            ),
                            onTap: () async {
                              final device = await widget.viewModel.crudDevice
                                  .getConnectedDevice();
                              debugPrint('device: $device');
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // 解析器列表区域
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      '解析服务器列表:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    child: widget.viewModel.parsers.isEmpty
                        ? const Center(child: Text('暂无解析器，请添加'))
                        : ListView.builder(
                            itemCount: widget.viewModel.parsers.length,
                            itemBuilder: (context, index) {
                              final parser = widget.viewModel.parsers[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
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
                                              : Icons.radio_button_unchecked,
                                          color: parser.isActive
                                              ? Colors.green
                                              : Colors.grey,
                                        ),
                                        tooltip:
                                            parser.isActive ? '当前活跃' : '设为活跃',
                                        onPressed: () async {
                                          final updatedParser = parser.copyWith(
                                            isActive: !parser.isActive,
                                          );
                                          await widget.viewModel
                                              .updateM3u8Parser(updatedParser);
                                          await _loadParsers();
                                        },
                                      ),
                                      // 编辑按钮
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        tooltip: '编辑',
                                        onPressed: () => _editParser(parser),
                                      ),
                                      // 删除按钮
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        tooltip: '删除',
                                        onPressed: () => _deleteParser(parser),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    // 选择此解析器
                                    if (!parser.isActive) {
                                      // 更新所有解析器状态
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: _addParser,
        tooltip: '添加解析器',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Future<void> _updateActiveParser(M3u8Parser activeParser) async {
  //   setState(() => _isLoading.value = true);
  //   try {
  //     // 更新所有解析器的活跃状态
  //     for (final parser in _parsers.value) {
  //       if (parser.isActive && parser.id != activeParser.id) {
  //         await widget.viewModel.updateM3u8Parser(
  //           parser.copyWith(isActive: false),
  //         );
  //       } else if (parser.id == activeParser.id && !parser.isActive) {
  //         await widget.viewModel.updateM3u8Parser(
  //           parser.copyWith(isActive: true),
  //         );
  //       }
  //     }
  //     await _loadParsers();
  // } catch (e) {
  //   _showErrorSnackBar('更新解析器状态失败: $e');
  // } finally {
  //   setState(() => _isLoading.value = false);
  // }
  // }

  @override
  void dispose() {
    super.dispose();
  }
}
