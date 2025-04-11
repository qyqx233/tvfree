import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:signals/signals_flutter.dart';
import 'package:tvfree/domain/model/device.dart';
import 'package:tvfree/internal/upnp/ssdp.dart';

class EditDevice extends StatefulWidget {
  const EditDevice({super.key, this.device});

  final UpnpDevice? device;

  @override
  State<EditDevice> createState() => _EditDeviceState();
}

class _EditDeviceState extends State<EditDevice> {
  final _formKey = GlobalKey<FormState>();
  late final friendlyName =
      TextEditingController(text: widget.device?.friendlyName);
  late final deviceIP =
      TextEditingController(text: extractIPFromURL(widget.device));
  // late final isConnected = signal(widget.device?.isConnected ?? false);
  bool get isNew => widget.device == null;

  // 从控制URL中提取IP地址
  String extractIPFromURL(UpnpDevice? device) {
    if (device != null && device.controlURL != null) {
      final url = device.controlURL!;
      final ip = Uri.parse(url).host;
      return ip;
    }
    return '';
  }

  Future<void> save(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final device = await UpnpDeviceDetector.testUpnp(deviceIP.text);
      if (kDebugMode) print(device.toString());
      if (!context.mounted) return;
      Navigator.of(context).pop(device);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text('编辑设备'),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => save(context),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    title: TextFormField(
                      controller: deviceIP,
                      decoration: const InputDecoration(
                        labelText: '设备IP',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入一个有效的IP地址';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: TextFormField(
                      controller: friendlyName,
                      decoration: const InputDecoration(
                        labelText: '设备名称',
                      ),
                      validator: (value) {
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
