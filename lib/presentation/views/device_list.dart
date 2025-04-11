import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:tvfree/domain/model/device.dart';
import 'package:tvfree/domain/signals/signal.dart';
import 'package:tvfree/domain/usecase/control_device.dart';
import 'package:tvfree/presentation/viewmodel/device_list.dart';
import 'package:tvfree/presentation/views/addr_choice.dart';
import 'package:tvfree/presentation/views/device_edit.dart';

class DeviceListView extends StatefulWidget {
  const DeviceListView({super.key, required this.viewModel});
  final DeviceListVM viewModel;

  @override
  State<DeviceListView> createState() => _DeviceListViewState();
}

class _DeviceListViewState extends State<DeviceListView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('投屏设备'),
        actions: [
          // 添加网络地址选择按钮
          IconButton(
            icon: const Icon(Icons.wifi),
            onPressed: _openNetworkSelector,
            tooltip: '选择网络地址',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              await widget.viewModel
                  .discoverDevices(networkAddressSignal.value!);
            },
            tooltip: '扫描可投屏设备',
          ),
        ],
      ),
      body: Column(
        children: [
          // 显示当前选择的网络地址
          Watch((context) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.network_wifi),
                        const SizedBox(width: 8),
                        Text('当前网络: $networkAddressSignal'),
                      ],
                    ),
                  ),
                ),
              )),
          // 设备列表
          Expanded(
            child: Watch((context) {
              if (widget.viewModel.devices.isEmpty) {
                return const Center(child: Text('暂无设备'));
              }
              return ListView.builder(
                itemCount: widget.viewModel.devices.length,
                itemBuilder: (context, index) {
                  final device = widget.viewModel.devices.value[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      title: Text(
                        device.friendlyName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('USN: ${device.usn}'),
                          Text(
                            '状态: ${device.isConnected ? '已连接' : '未连接'}',
                            style: TextStyle(
                              color: device.isConnected
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 连接/断开按钮
                          IconButton(
                            icon: Icon(
                              device.isConnected ? Icons.link_off : Icons.link,
                              color: device.isConnected
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            tooltip: device.isConnected ? '断开连接' : '连接',
                            onPressed: () async {
                              if (mounted) {
                                await widget.viewModel.toggleConnect(
                                  device,
                                  device.isConnected
                                      ? DeviceState.disconnected
                                      : DeviceState.connected,
                                );
                              }
                            },
                          ),
                          // 删除按钮
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            tooltip: '删除设备',
                            onPressed: () {
                              _confirmDeleteDevice(device);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        // 点击整个列表项时的操作，可以显示详情或编辑
                        _showDeviceDetails(device);
                      },
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result =
              await Navigator.of(context).push<UpnpDevice?>(MaterialPageRoute(
            builder: (context) => const EditDevice(),
            fullscreenDialog: true,
          ));
          if (result != null && mounted) {
            debugPrint(result.toString());
            await widget.viewModel.addDevice(result);
          }
        },
      ),
    );
  }

  // 打开网络地址选择器
  void _openNetworkSelector() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            NetworkAddressSelector(onAddressSelected: (address) async {
          networkAddressSignal.value = address;
        }),
      ),
    );
  }

  void _confirmDeleteDevice(UpnpDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除设备'),
        content: Text('确定要删除设备 "${device.friendlyName}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await widget.viewModel.deleteDevice(device);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 显示设备详情
  void _showDeviceDetails(UpnpDevice device) async {
    final result = await Navigator.of(context).push<UpnpDevice?>(
      MaterialPageRoute(
        builder: (context) => EditDevice(device: device),
        fullscreenDialog: true,
      ),
    );

    if (result != null && mounted) {
      // await widget.viewModel.updateDevice(result);
    }
  }
}
