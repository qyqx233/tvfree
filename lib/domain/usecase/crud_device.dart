import 'package:tvfree/domain/model/device.dart';
import 'package:tvfree/domain/repository/kvs.dart';
import 'package:tvfree/domain/repository/upnps.dart';

class CrudDevice {
  final UpnpRepository _upnpRepo;
  final KvRepository _kvRepo;

  CrudDevice(this._upnpRepo, this._kvRepo);

  Future<List<UpnpDevice>> getAll() {
    return _upnpRepo.listAll();
  }

  Future<void> add(UpnpDevice device) async {
    await _upnpRepo.add(device);
  }

  Future<void> addMany(List<UpnpDevice> devices) async {
    await _upnpRepo.addMany(devices);
  }

  Future<void> remove(int id) async {
    final current = await _upnpRepo.get(id);
    if (current == null) {
      throw Exception('设备不存在');
    }
    await _upnpRepo.remove(current);
  }

  Future<void> removeAll() async {
    await _upnpRepo.removeAllDevices();
  }

  Future<void> update(UpnpDevice device) async {
    await _upnpRepo.update(device);
  }

  Future<UpnpDevice?> getConnectedDevice() async {
    return await _upnpRepo.getConnectedDevice();
  }
}
