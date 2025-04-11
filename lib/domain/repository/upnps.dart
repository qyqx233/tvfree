import 'package:tvfree/domain/model/device.dart';

abstract class UpnpRepository {
  Future<List<UpnpDevice>> getAll();
  Stream<List<UpnpDevice>> watchAll();
  Future<List<UpnpDevice>> listAll();
  Future<UpnpDevice?> get(int id);
  Future<int> add(UpnpDevice device);
  Future<void> addMany(List<UpnpDevice> device);
  Future<int> search(UpnpDevice device);
  Future<void> remove(UpnpDevice device);
  Future<void> update(UpnpDevice device);
  Future<void> removeCompleted();
  Future<int> removeAllDevices();
  Future<UpnpDevice?> getConnectedDevice();
}
