import 'package:flutter/foundation.dart';
import 'package:tvfree/domain/model/device.dart';
import 'package:tvfree/domain/repository/upnps.dart';
import 'package:tvfree/internal/castscreen/castscreen.dart';
import 'package:tvfree/internal/network/addr.dart';
import 'package:tvfree/internal/upnp/ssdp.dart';
import 'package:tvfree/internal/util/stream.dart';

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
    // debugPrint("发现设备 $ips");
    final results = await Streams.concurrent(
        dataList: ips,
        process: UpnpDeviceDetector.testUpnp,
        maxConcurrency: 90);
    return results;
  }

  Future<bool> connectCast(UpnpDevice? device) async {
    device ??= await _upnpRepository.getConnectedDevice();
    if (device == null) {
      return false;
    }
    final devs = await CastScreen.discoverByIP(
        ip: Uri.parse(device.controlURL!).host,
        ST: "urn:schemas-upnp-org:device:MediaRenderer:1",
        timeout: Duration(seconds: 2));
    debugPrint("发现设备 $devs");
    if (devs.isEmpty) {
      return false; // Return false to indicate unsuccessful connection
    }
    _device = devs.first; // Return true to indicate successful connection
    return true;
  }

  Future<bool> toggleConnect(int id, DeviceState state) async {
    final upnp = await _upnpRepository.get(id);
    if (upnp == null) {
      throw Exception('Device not found');
    }
    if (state == DeviceState.connected) {
      if (!await connectCast(upnp)) {
        return false;
      }
      upnp.isConnected = true;
    } else {
      upnp.isConnected = false;
    }
    await _upnpRepository.update(upnp);
    return state == DeviceState.connected
        ? true
        : false; // Return true to indicate successful connection
  }

  Future<bool> castScreen(String url) async {
    debugPrint("device=$_device");
    if (_device == null) {
      if (!await connectCast(null)) {
        return false;
      }
    }

    final output =
        await _device!.setAVTransportURI(SetAVTransportURIInput(url));
    debugPrint(output.toString());
    return true;
  }
}
