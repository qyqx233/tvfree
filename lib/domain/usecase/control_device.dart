import 'package:collection/collection.dart';
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

  ControlDevice(this._upnpRepository) {
    // debugPrint(">>>> ControlDevice init");
  }

  Future<List<UpnpDevice>> checkExists(List<UpnpDevice> upnps) async {
    final results = await Future.wait(upnps
        .map((x) => UpnpDeviceDetector.testUpnp(Uri.parse(x.controlURL!).host,
            fetch: false))
        .toList());
    final zipped = IterableZip([upnps, results]).toList();
    // final connected = upnps.where((x) => x.isConnected).firstOrNull;
    for (var element in zipped) {
      if (element[1] == null && element[0]!.isConnected) {
        element[0]!.isConnected = false;
        await _upnpRepository.add(element[0]!);
      }
    }
    final exists = List<UpnpDevice>.from(
        zipped.where((x) => x[1] != null).map((x) => x[0] as UpnpDevice));
    return exists;
  }

  Future<List<UpnpDevice?>> discoverDeviceold(String ip) async {
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

  Future<List<UpnpDevice?>> discoverDevice(String? ip) async {
    if (ip != null) {
      var ips = ([ip])
          .map((x) => NetAddr.getAllIPsInSubnet(x))
          .expand((x) => x)
          .toList();
      // debugPrint("发现设备 $ips");
      return await Streams.concurrent(
          dataList: ips,
          process: UpnpDeviceDetector.testUpnp,
          maxConcurrency: 90);
    }
    return await UpnpDeviceDetector.scanUpnp();
  }

  Future<bool> connectCast(UpnpDevice? device) async {
    device ??= await _upnpRepository.getConnectedDevice();
    if (device == null) {
      return false;
    }
    debugPrint("连接设备 ${device.controlURL} ${device.descriptionURL}");
    final devs = await CastScreen.connectTo(device.descriptionURL);
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
      final connected = await _upnpRepository.getConnectedDevice();
      if (connected != null) {
        if (connected.id == upnp.id) {
          return true; // Already connected, no action needed
        } else {
          connected.isConnected = false;
          await _upnpRepository.update(connected);
        }
      }
      if (!await connectCast(upnp)) {
        return false;
      }
      upnp.isConnected = true;
    } else {
      // await _device.client.close();
      upnp.isConnected = false;
    }
    await _upnpRepository.update(upnp);
    return state == DeviceState.connected
        ? true
        : false; // Return true to indicate successful connection
  }

  Future<bool> castScreen(String url) async {
    // debugPrint("device=$_device");
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
