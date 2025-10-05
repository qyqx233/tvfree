import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:tvfree/presentation/viewmodel/resource.dart';

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
    widget.viewModel.getStorageInfo('.');
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
          StorageResourceView(viewModel: widget.viewModel),
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

  Future<void> _parseM3U8(String m3u8Url) async {
    await widget.viewModel.parseM3U8(m3u8Url);
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

  Widget _buildParseResults() {
    return Watch((context) {
      final results = widget.viewModel.searchResults.value;
      if (results == null) return const SizedBox.shrink();

      if (results.code != 0) {
        return Text('解析失败: ${results.msg}');
      }
      debugPrint("============ ${results.data.length}");

      // 转换数据结构：按集数分组，每集对应多个播放渠道
      final Map<String, List<Map<String, dynamic>>> episodesMap = {};

      // Iterate through all source categories
      results.data.forEach((source, episodesBySource) {
        // Iterate through episodes in each source
        episodesBySource.forEach((episode, episodeDataList) {
          // Create a key for this episode
          final episodeKey = episode;

          if (!episodesMap.containsKey(episodeKey)) {
            episodesMap[episodeKey] = [];
          }

          // Add all data for this episode from the current source
          for (final episodeData in episodeDataList) {
            episodesMap[episodeKey]!.add({
              'source': source.toString(),
              'episode': episode,
              'data': episodeData,
            });
          }
        });
      });

      return Expanded(
        child: ListView(
          children: episodesMap.entries.map((episodeEntry) {
            final episode = episodeEntry.key;
            final channels = episodeEntry.value;

            return ExpansionTile(
              title: Text('第$episode集'),
              children: channels.map((channelInfo) {
                final source = channelInfo['source'];
                final episode = channelInfo['episode'];
                final data = channelInfo['data'];

                return ListTile(
                  title: Text('来源: $source'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('集数: 第$episode集'),
                      Text('M3U8: ${data.m3u8}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.cast),
                    onPressed: () async {
                      debugPrint('投屏: ${data.m3u8}');
                      final device = await widget.viewModel.crudDevice
                          .getConnectedDevice();
                      if (device == null) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('未连接设备')),
                        );
                        return;
                      }
                      await widget.viewModel.controlDevice
                          .castScreen(data.m3u8);
                    },
                    tooltip: '投屏',
                  ),
                  onTap: () {
                    debugPrint('播放: ${data.m3u8}');
                  },
                );
              }).toList(),
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
            _buildParseResults(),
          ],
        ),
      ),
    );
  }
}

class StorageResourceView extends StatefulWidget {
  const StorageResourceView({super.key, required this.viewModel});

  final ResourceVM viewModel;

  @override
  State<StorageResourceView> createState() => _StorageResourceViewState();
}

class _StorageResourceViewState extends State<StorageResourceView>
    with SignalsMixin {
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

      if (storageInfo.err.isNotEmpty) {
        return Center(
          child: Text('错误: ${storageInfo.err}'),
        );
      }

      final dirs = storageInfo.dirs ?? [];
      final files = storageInfo.files ?? [];

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
            final dirName = dirs[index];
            return ListTile(
              leading: const Icon(Icons.folder, color: Colors.blue),
              title: Text(dirName),
              onTap: () => widget.viewModel.enterDirectory(dirName),
              trailing: const Icon(Icons.arrow_forward_ios),
            );
          } else {
            // 文件项
            final fileName = files[index - dirs.length];
            final isVideoFile = _isVideoFile(fileName);
            final filePath = widget.viewModel.currentPath.value == '.'
                ? fileName
                : '${widget.viewModel.currentPath.value}/$fileName';

            return ListTile(
              leading: Icon(
                isVideoFile ? Icons.video_file : Icons.insert_drive_file,
                color: isVideoFile ? Colors.red : Colors.grey,
              ),
              title: Text(fileName),
              trailing: isVideoFile
                  ? IconButton(
                      icon: const Icon(Icons.cast),
                      onPressed: () async {
                        debugPrint('投屏: $filePath');
                        final device = await widget.viewModel.crudDevice
                            .getConnectedDevice();
                        if (device == null) {
                          if (!context.mounted) return;
                          _showErrorSnackBar('未连接设备');
                          return;
                        }
                        await widget.viewModel.controlDevice
                            .castScreen(filePath);
                      },
                      tooltip: '投屏',
                    )
                  : null,
              onTap: () {
                if (isVideoFile) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('视频文件: $fileName')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('选中文件: $fileName')),
                  );
                }
              },
            );
          }
        },
      );
    });
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
