import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals/signals_flutter.dart';
import 'package:tvfree/domain/signals/signals.dart';
import 'package:tvfree/presentation/viewmodel/resource.dart';
import 'package:tvfree/data/repository/restful.dart';

class ResourceView extends StatefulWidget {
  const ResourceView({super.key, required this.viewModel});

  final ResourceVM viewModel;

  @override
  State<ResourceView> createState() => _ResourceViewState();
}

class _ResourceViewState extends State<ResourceView>
    with SingleTickerProviderStateMixin, SignalsMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 初始化时加载存储信息
    if (remoteStorageUrl.value.isNotEmpty) widget.viewModel.getStorageInfo('.');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('资源管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '远程资源', icon: Icon(Icons.cloud)),
            Tab(text: '本地存储', icon: Icon(Icons.storage)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RemoteResourceView(viewModel: widget.viewModel),
          LocalStorageView(viewModel: widget.viewModel),
        ],
      ),
    );
  }
}

class RemoteResourceView extends StatefulWidget {
  const RemoteResourceView({super.key, required this.viewModel});

  final ResourceVM viewModel;

  @override
  State<RemoteResourceView> createState() => _RemoteResourceViewState();
}

class _RemoteResourceViewState extends State<RemoteResourceView>
    with SignalsMixin {
  late final searchText = createSignal('');

  Future<void> _searchTv() async {
    await widget.viewModel.searchTv(searchText.value);
  }

  Widget _buildSearchSection() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              labelText: '搜索影视剧',
              hintText: '请输入影视剧名称',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => searchText.value = value,
            onSubmitted: (_) => _searchTv(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _searchTv,
          child: const Text('搜索'),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Watch((context) {
      if (widget.viewModel.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildSearchResults() {
    return Watch((context) {
      final results = widget.viewModel.searchResults.value;
      if (results == null) return const SizedBox.shrink();

      if (results.code != 200) {
        return Text('解析失败: ${results.msg}');
      }

      // 新的数据结构：按集数分组，每集对应多个播放渠道
      return Expanded(
        child: ListView(
          children: results.data.entries.map((episodeEntry) {
            final episode = episodeEntry.key;
            final channels = episodeEntry.value;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ExpansionTile(
                title: Text(
                  '第$episode集',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text('共 ${channels.length} 个播放链接'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        // 显示每集下的所有记录，包括渠道名称和m3u8链接
                        ...channels.asMap().entries.map((channelEntry) {
                          final index = channelEntry.key;
                          final channelData = channelEntry.value;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '渠道: ${channelData.channel}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cast, size: 20),
                                      onPressed: () async {
                                        final device = await widget
                                            .viewModel.crudDevice
                                            .getConnectedDevice();
                                        if (device == null) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text('未连接设备')),
                                          );
                                          return;
                                        }
                                        await widget.viewModel.controlDevice
                                            .castScreen(channelData.m3u8);
                                      },
                                      tooltip: '投屏',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // 显示m3u8链接
                                Container(
                                  padding: const EdgeInsets.all(6.0),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4.0),
                                    border:
                                        Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.link,
                                          size: 16, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          channelData.m3u8,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue,
                                            fontFamily: 'monospace',
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.copy, size: 16),
                                        onPressed: () async {
                                          // 复制m3u8链接到剪贴板
                                          await Clipboard.setData(ClipboardData(
                                              text: channelData.m3u8));
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text('链接已复制到剪贴板')),
                                          );
                                        },
                                        tooltip: '复制链接',
                                        constraints: const BoxConstraints(
                                          minWidth: 24,
                                          minHeight: 24,
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('影视资源查询'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchSection(),
            const SizedBox(height: 16),
            _buildLoadingIndicator(),
            // _buildSearchResults(),
            _buildSearchResults(),
          ],
        ),
      ),
    );
  }
}

class LocalStorageView extends StatefulWidget {
  const LocalStorageView({super.key, required this.viewModel});

  final ResourceVM viewModel;

  @override
  State<LocalStorageView> createState() => _LocalStorageViewState();
}

class _LocalStorageViewState extends State<LocalStorageView> with SignalsMixin {
  // 检查是否为视频文件
  bool _isVideoFile(String fileName) {
    final videoExtensions = [
      '.mp4',
      '.avi',
      '.mkv',
      '.mov',
      '.wmv',
      '.flv',
      '.webm',
      '.m4v',
      '.3gp',
      '.ogv',
      '.ts',
      '.m2ts'
    ];
    final extension = fileName.toLowerCase().split('.').last;
    return videoExtensions.contains('.$extension');
  }

  // 显示错误消息
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildPathNavigation() {
    return Watch((context) {
      final currentPath = widget.viewModel.currentPath.value;
      final canGoBack = widget.viewModel.pathHistory.length > 1;

      return Container(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: canGoBack ? () => widget.viewModel.goBack() : null,
              tooltip: '返回上级',
            ),
            Expanded(
              child: Text(
                '当前路径: $currentPath',
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => widget.viewModel.getStorageInfo(currentPath),
              tooltip: '刷新',
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStorageLoadingIndicator() {
    return Watch((context) {
      if (widget.viewModel.storageLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildStorageContent() {
    return Watch((context) {
      final storageInfo = widget.viewModel.storageInfo.value;
      if (storageInfo == null) return const SizedBox.shrink();

      // 分离目录和文件
      final dirs = <CaddyFileInfo>[];
      final files = <CaddyFileInfo>[];

      for (final item in storageInfo) {
        if (item.is_dir) {
          dirs.add(item);
        } else {
          files.add(item);
        }
      }

      if (dirs.isEmpty && files.isEmpty) {
        return const Center(
          child: Text('此目录为空'),
        );
      }

      return ListView.builder(
        itemCount: dirs.length + files.length,
        itemBuilder: (context, index) {
          if (index < dirs.length) {
            // 目录项
            final dirInfo = dirs[index];
            return ListTile(
              leading: const Icon(Icons.folder, color: Colors.blue),
              title: Text(dirInfo.name),
              onTap: () => widget.viewModel.enterDirectory(dirInfo.name),
              trailing: const Icon(Icons.arrow_forward_ios),
            );
          } else {
            // 文件项
            final fileInfo = files[index - dirs.length];
            final isVideoFile = _isVideoFile(fileInfo.name);
            final filePath = widget.viewModel.currentPath.value == '.'
                ? fileInfo.name
                : '${widget.viewModel.currentPath.value}/${fileInfo.name}';

            return ListTile(
              leading: Icon(
                isVideoFile ? Icons.video_file : Icons.insert_drive_file,
                color: isVideoFile ? Colors.red : Colors.grey,
              ),
              title: Text(fileInfo.name),
              subtitle: Text(
                  '${_formatFileSize(fileInfo.size)} • ${_formatDate(fileInfo.mod_time)}'),
              trailing: isVideoFile
                  ? IconButton(
                      icon: const Icon(Icons.cast),
                      onPressed: () async {
                        final castUrl = "${remoteStorageUrl.value}/$filePath";
                        debugPrint('投屏文件: $castUrl');
                        final device = await widget.viewModel.crudDevice
                            .getConnectedDevice();
                        if (device == null) {
                          if (!context.mounted) return;
                          _showErrorSnackBar('未连接设备');
                          return;
                        }
                        await widget.viewModel.controlDevice
                            .castScreen(castUrl);
                      },
                      tooltip: '投屏',
                    )
                  : null,
              onTap: () {
                if (isVideoFile) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('视频文件: ${fileInfo.name}')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('选中文件: ${fileInfo.name}')),
                  );
                }
              },
            );
          }
        },
      );
    });
  }

  // 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // 格式化日期
  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPathNavigation(),
        const Divider(height: 1),
        Expanded(
          child: Stack(
            children: [
              _buildStorageContent(),
              _buildStorageLoadingIndicator(),
            ],
          ),
        ),
      ],
    );
  }
}
