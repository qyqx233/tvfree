import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signals/signals_flutter.dart';
import 'package:tvfree/domain/model/device.dart';
import 'package:tvfree/domain/usecase/control_device.dart';
import 'package:tvfree/domain/usecase/crud_device.dart';

class DeviceListVM {
  // 单例实例
  static DeviceListVM? _instance;

  // 获取单例实例的工厂方法
  factory DeviceListVM({
    required CrudDevice crudDevice,
    required ControlDevice controlDevice,
  }) {
    _instance ??= DeviceListVM._internal(
      crudDevice: crudDevice,
      controlDevice: controlDevice,
    );
    return _instance!;
  }

  // 私有构造函数
  DeviceListVM._internal({
    required CrudDevice crudDevice,
    required ControlDevice controlDevice,
  })  : _crudDevice = crudDevice,
        _controlDevice = controlDevice {
    init();
  }

  final CrudDevice _crudDevice;
  final ControlDevice _controlDevice;
  final streamController = StreamController<List<UpnpDevice>>.broadcast();
  final devices = listSignal<UpnpDevice>([]);
  late final _connectDevices = connect(devices);
  var _isDiscovering = false;
  bool _isInitialized = false;

  // 其余方法保持不变
  Future<void> deleteDevice(UpnpDevice device) async {
    await _crudDevice.remove(device.id!);
    _crudDevice.getAll().then((value) {
      streamController.sink.add(value);
    });
  }

  void init() {
    if (_isInitialized) return;
    _isInitialized = true;

    _connectDevices << streamController.stream;
    _crudDevice.getAll().then((value) {
      streamController.sink.add(value);
    });
  }

  Future<void> addDevice(UpnpDevice device) async {
    await _crudDevice.add(device);
    streamController.sink.add(await _crudDevice.getAll());
  }

  Future<bool> toggleConnect(UpnpDevice device, DeviceState state) async {
    final isConnected = await _controlDevice.toggleConnect(device.id!, state);
    streamController.sink.add(devices.map((e) {
      if (e.id == device.id) {
        return e.copyWith(isConnected: isConnected);
      }
      return e;
    }).toList());
    return isConnected;
  }

  Future<void> discoverDevices(String ip) async {
    if (_isDiscovering) {
      return;
    }
    try {
      _isDiscovering = true;
      final discoverNew = await _controlDevice.discoverDevice(ip);
      final deviceOrigin = devices.peek();
      final deviceNew =
          discoverNew.where((v) => !deviceOrigin.contains(v)).toList();
      await _crudDevice.addMany(deviceNew);
      streamController.sink.add([...deviceOrigin, ...deviceNew].toList());
      return;
    } finally {
      _isDiscovering = false;
    }
  }

  // 重置单例实例的方法（主要用于测试）
  static void reset() {
    if (_instance != null) {
      _instance!.dispose();
      _instance = null;
    }
  }

  void dispose() {
    if (kDebugMode) {}
    streamController.close();
    _connectDevices.dispose();
    devices.dispose();
    _isInitialized = false;
    if (kDebugMode) {}
  }
}
