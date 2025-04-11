import 'dart:async';

import 'package:tvfree/domain/model/device.dart';
import 'package:tvfree/objectbox.g.dart';

import '../../domain/repository/upnps.dart';

class UpnpRepositoryImpl implements UpnpRepository {
  final Store database;

  UpnpRepositoryImpl(this.database);
  @override
  Future<int> add(UpnpDevice device) async {
    final id = database.box<UpnpDevice>().put(device);
    return id;
  }

  @override
  Future<List<UpnpDevice>> getAll() async {
    final res = database.box<UpnpDevice>().getAll();
    return res;
  }

  @override
  Future<void> remove(UpnpDevice device) async {
    database.box<UpnpDevice>().remove(device.id!);
  }

  @override
  Future<void> update(UpnpDevice device) async {
    database.box<UpnpDevice>().put(device);
  }

  @override
  Future<UpnpDevice?> get(int id) async {
    return database.box<UpnpDevice>().get(id);
  }

  @override
  Future<void> removeCompleted() async {}

  @override
  Future<int> search(UpnpDevice device) async {
    database.box<UpnpDevice>().put(device);
    return 0;
  }

  @override
  Future<int> removeAllDevices() async {
    return 0;
  }

  @override
  Future<List<UpnpDevice>> listAll() async {
    return await getAll(); // 返回所有设备列表
  }

  @override
  Stream<List<UpnpDevice>> watchAll() {
    throw UnimplementedError();
  }

  @override
  Future<void> addMany(List<UpnpDevice> devices) async {
    database.box<UpnpDevice>().putMany(devices);
    return;
  }

  @override
  Future<UpnpDevice?> getConnectedDevice() async {
    final query = database
        .box<UpnpDevice>()
        .query(UpnpDevice_.isConnected.equals(true))
        .build();
    final result = query.findFirst();
    query.close();
    return result;
  }
}
