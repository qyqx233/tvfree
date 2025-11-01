import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:tvfree/domain/signals/signals.dart';
import 'package:tvfree/presentation/viewmodel/m3u8_parser.dart';

class M3u8ParserView extends StatefulWidget {
  const M3u8ParserView({super.key, required this.viewModel});
  final M3u8ParserVM viewModel;

  @override
  State<M3u8ParserView> createState() => _M3u8ParserViewState();
}

class _M3u8ParserViewState extends State<M3u8ParserView> {
  final _urlController = TextEditingController();
  final _startEpisodeController = TextEditingController(text: '1');
  final _endEpisodeController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.viewModel.currentUrl.value;
    _startEpisodeController.text =
        widget.viewModel.startEpisode.value.toString();
    _endEpisodeController.text = widget.viewModel.endEpisode.value.toString();
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
      if (widget.viewModel.isBatchMode.value) {
        // 批量解析模式
        final startEpisode = int.tryParse(_startEpisodeController.text);
        final endEpisode = int.tryParse(_endEpisodeController.text);

        if (startEpisode == null || endEpisode == null) {
          _showErrorSnackBar('请输入有效的起始和终止集数');
          return;
        }

        if (startEpisode > endEpisode) {
          _showErrorSnackBar('起始集数不能大于终止集数');
          return;
        }
        await widget.viewModel.batchParseM3u8(
          widget.viewModel.currentUrl.value,
          startEpisode,
          endEpisode,
        );
      } else {
        // 单集解析模式
        final results =
            await widget.viewModel.parseM3u8(widget.viewModel.currentUrl.value);
        widget.viewModel.parseResults.value = results;
      }
    } catch (e) {
      _showErrorSnackBar('解析失败: $e');
    } finally {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('视频解析器'),
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
                  // 单集/批量解析切换标签
                  Row(
                    children: [
                      Expanded(
                        child: Watch((context) => ToggleButtons(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(8)),
                              selectedBorderColor: Colors.blue,
                              selectedColor: Colors.white,
                              fillColor: Colors.blue,
                              color: Colors.blue,
                              constraints: const BoxConstraints(
                                minHeight: 40.0,
                                minWidth: 100.0,
                              ),
                              isSelected: [
                                !widget.viewModel.isBatchMode.value,
                                widget.viewModel.isBatchMode.value,
                              ],
                              onPressed: (index) {
                                widget.viewModel.isBatchMode.value = index == 1;
                              },
                              children: const [
                                Text('单集解析'),
                                Text('批量解析'),
                              ],
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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

                  // 批量解析时的集数输入
                  Watch((context) => widget.viewModel.isBatchMode.value
                      ? Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _startEpisodeController,
                                    decoration: const InputDecoration(
                                      labelText: '起始集数',
                                      hintText: '输入起始集数',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      final episode = int.tryParse(value);
                                      if (episode != null) {
                                        widget.viewModel.startEpisode.value =
                                            episode;
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: _endEpisodeController,
                                    decoration: const InputDecoration(
                                      labelText: '终止集数',
                                      hintText: '输入终止集数',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      final episode = int.tryParse(value);
                                      if (episode != null) {
                                        widget.viewModel.endEpisode.value =
                                            episode;
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // 批量解析进度显示
                            if (widget.viewModel.batchProgress.value.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.blue.withOpacity(0.3)),
                                ),
                                child: Text(
                                  widget.viewModel.batchProgress.value,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                          ],
                        )
                      : const SizedBox.shrink()),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.search),
                          label: Text(widget.viewModel.isBatchMode.value
                              ? '批量解析'
                              : '解析'),
                          onPressed: widget.viewModel.isLoading.value
                              ? null
                              : _parseM3u8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 只在单集解析模式下显示"下一个视频"按钮
                      Watch((context) => !widget.viewModel.isBatchMode.value
                          ? Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.skip_next),
                                label: const Text('下一个视频'),
                                onPressed: () {
                                  final current =
                                      widget.viewModel.currentUrl.value.trim();
                                  final match = RegExp(r"(\d+)\.html$")
                                      .firstMatch(current);
                                  if (match == null) {
                                    _showErrorSnackBar('网址末尾不含"数字.html"，无法前进');
                                    return;
                                  }
                                  final numStr = match.group(1)!;
                                  final currentNum = int.tryParse(numStr);
                                  if (currentNum == null) {
                                    _showErrorSnackBar('解析集数失败');
                                    return;
                                  }
                                  final newUrl = current.replaceRange(
                                    match.start,
                                    match.end,
                                    '${currentNum + 1}.html',
                                  );
                                  _urlController.text = newUrl;
                                  widget.viewModel.currentUrl.value = newUrl;
                                },
                              ),
                            )
                          : const SizedBox.shrink()),
                    ],
                  ),
                ],
              ),
            ),

            // 解析结果区域
            if ((widget.viewModel.parseResults.isNotEmpty &&
                    !widget.viewModel.isBatchMode.value) ||
                (widget.viewModel.batchParseResults.value.isNotEmpty &&
                    widget.viewModel.isBatchMode.value))
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        widget.viewModel.isBatchMode.value
                            ? '批量解析结果:'
                            : '解析结果:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Watch((context) {
                        // 单集解析模式
                        if (!widget.viewModel.isBatchMode.value) {
                          return ListView.builder(
                            itemCount: widget.viewModel.parseResults.length,
                            itemBuilder: (context, index) {
                              final url = widget.viewModel.parseResults[index];
                              return ListTile(
                                title: Text(url),
                                trailing: IconButton(
                                  icon: const Icon(Icons.cast),
                                  onPressed: () async {
                                    final device = await widget
                                        .viewModel.crudDevice
                                        .getConnectedDevice();
                                    if (device == null) {
                                      if (!context.mounted) return;
                                      _showErrorSnackBar('未连接设备');
                                      return;
                                    }
                                    await widget.viewModel.controlDevice
                                        .castScreen(url);
                                  },
                                  tooltip: '投屏',
                                ),
                                onTap: () async {
                                  final device = await widget
                                      .viewModel.crudDevice
                                      .getConnectedDevice();
                                  debugPrint('device: $device');
                                },
                              );
                            },
                          );
                        }
                        // 批量解析模式
                        else {
                          final batchResults =
                              widget.viewModel.batchParseResults.value;
                          final sortedEpisodes = batchResults.keys.toList()
                            ..sort();

                          return ListView.builder(
                            itemCount: sortedEpisodes.length,
                            itemBuilder: (context, index) {
                              final episode = sortedEpisodes[index];
                              final episodeResults =
                                  batchResults[episode] ?? [];

                              return ExpansionTile(
                                title: Text(
                                    '第 $episode 集 (${episodeResults.length} 个视频)'),
                                children: episodeResults.map((result) {
                                  return ListTile(
                                    title: Text(result.name ?? result.m3u8),
                                    subtitle: result.url != null &&
                                            result.url!.isNotEmpty
                                        ? Text('来源: ${result.url}')
                                        : null,
                                    trailing: IconButton(
                                      icon: const Icon(Icons.cast),
                                      onPressed: () async {
                                        final device = await widget
                                            .viewModel.crudDevice
                                            .getConnectedDevice();
                                        if (device == null) {
                                          if (!context.mounted) return;
                                          _showErrorSnackBar('未连接设备');
                                          return;
                                        }
                                        await widget.viewModel.controlDevice
                                            .castScreen(result.m3u8);
                                      },
                                      tooltip: '投屏',
                                    ),
                                    onTap: () async {
                                      final device = await widget
                                          .viewModel.crudDevice
                                          .getConnectedDevice();
                                      debugPrint('device: $device');
                                    },
                                  );
                                }).toList(),
                              );
                            },
                          );
                        }
                      }),
                    ),
                  ],
                ),
              ),
          ],
        );
      }),
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
    _urlController.dispose();
    _startEpisodeController.dispose();
    _endEpisodeController.dispose();
    super.dispose();
  }
}
