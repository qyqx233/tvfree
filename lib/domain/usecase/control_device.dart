import 'package:flutter/foundation.dart';
import 'package:tvfree/internal/castscreen/castscreen.dart';
import 'package:tvfree/internal/network/addr.dart';
import 'package:tvfree/internal/upnp/ssdp.dart';
import 'package:tvfree/internal/util/stream.dart';

import '../model/device.dart';
import '../repository/upnps.dart';

enum DeviceState {
  connected,
  disconnected,
}

class ControlDevice {
  final UpnpRepository _upnpRepository;
  Device? _device;

  ControlDevice(this._upnpRepository);

  Future<List<UpnpDevice>> discoverDevice(String ip) async {
    var ips = ([ip])
        .map((x) => NetAddr.getAllIPsInSubnet(x))
        .expand((x) => x)
        .toList();
    final results = await Streams.concurrent(
        dataList: ips,
        process: UpnpDeviceDetector.testUpnp,
        maxConcurrency: 100);
    return results;
  }

  Future<bool> toggleConnect(int id, DeviceState state) async {
    final device = await _upnpRepository.get(id);
    if (device == null) {
      throw Exception('Device not found');
    }
    if (state == DeviceState.connected) {
      final devs = await CastScreen.discoverByIP(
          ip: Uri.parse(device.controlURL!).host,
          ST: "urn:schemas-upnp-org:device:MediaRenderer:1",
          timeout: Duration(seconds: 2));
      if (devs.isEmpty) {
        return false; // Return false to indicate unsuccessful connection
      }
      _device = devs.first;
      debugPrint("连接成功 ${_device.toString()}");
      // _device?.alive();
      device.isConnected = true;
    } else {
      device.isConnected = false;
    }
    await _upnpRepository.update(device);
    return state == DeviceState.connected
        ? true
        : false; // Return true to indicate successful connection
  }

  Future<bool> castScreen(String url) async {
    debugPrint(_device.toString());
    if (_device == null) {
      throw Exception('Device not connected');
    }

    await _device!.setAVTransportURI(SetAVTransportURIInput(url));
    return true;
  }
}
