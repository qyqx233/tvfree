import 'package:flutter/material.dart';
import 'package:tvfree/internal/network/addr.dart';

class NetworkAddressSelector extends StatefulWidget {
  final Function(String) onAddressSelected;
  final String title;

  const NetworkAddressSelector({
    super.key,
    required this.onAddressSelected,
    this.title = '选择网络地址',
  });

  @override
  State<NetworkAddressSelector> createState() => _NetworkAddressSelectorState();
}

class _NetworkAddressSelectorState extends State<NetworkAddressSelector> {
  List<String> _addresses = [];
  bool _isLoading = true;
  String? _selectedAddress;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final addresses = await NetAddr.localIPv4MCastAddrs();
      setState(() {
        _addresses = addresses;
        _isLoading = false;
        if (addresses.isNotEmpty) {
          _selectedAddress = addresses.first;
        }
      });
    } catch (e) {
      setState(() {
        _error = '获取网络地址失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _buildBody(),
      floatingActionButton: _selectedAddress != null
          ? FloatingActionButton(
              onPressed: () {
                widget.onAddressSelected(_selectedAddress!);
                Navigator.of(context).pop();
              },
              child: const Icon(Icons.check),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadAddresses,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_addresses.isEmpty) {
      return const Center(
        child: Text('未找到可用的网络地址'),
      );
    }

    return ListView.builder(
      itemCount: _addresses.length,
      itemBuilder: (context, index) {
        final address = _addresses[index];
        return RadioListTile<String>(
          title: Text(address),
          subtitle: Text('子网: ${_getSubnetInfo(address)}'),
          value: address,
          groupValue: _selectedAddress,
          onChanged: (value) {
            setState(() {
              _selectedAddress = value;
            });
          },
        );
      },
    );
  }

  String _getSubnetInfo(String ip) {
    final parts = ip.split('.');
    if (parts.length == 4) {
      return '${parts[0]}.${parts[1]}.${parts[2]}.*';
    }
    return '未知';
  }
}

// 使用示例:
// Navigator.of(context).push(
//   MaterialPageRoute(
//     builder: (context) => NetworkAddressSelector(
//       onAddressSelected: (address) {
//         print('选择的地址: $address');
//         // 处理选择的地址
//       },
//     ),
//   ),
// );
