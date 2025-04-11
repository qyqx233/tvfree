import 'package:objectbox/objectbox.dart';

@Entity()
class UpnpDevice {
  int? id;
  String usn;
  String friendlyName;
  String descriptionURL;
  String? controlURL;
  String? manufacturer;
  String? serviceType;
  String? eventSubURL;
  String? scpdURL;
  String? presentationURL;
  bool isConnected;

  UpnpDevice({
    required this.usn,
    required this.friendlyName,
    required this.descriptionURL,
    this.id,
    this.manufacturer,
    this.controlURL,
    this.serviceType,
    this.eventSubURL,
    this.scpdURL,
    this.presentationURL,
    this.isConnected = false,
  });

  factory UpnpDevice.fromJson(Map<String, dynamic> json) => UpnpDevice(
        id: json['id'] as int,
        usn: json['usn'] as String,
        descriptionURL: json['descriptionURL'],
        friendlyName: json['friendlyName'] as String,
        manufacturer: json['manufacturer'],
        serviceType: json['serviceType'],
        controlURL: json['controlURL'],
        eventSubURL: json['eventSubURL'],
        scpdURL: json['scpdURL'],
        presentationURL: json['presentationURL'],
      );

  Map<String, dynamic> toJson() => {
        if (id != -1) 'id': id,
        'usn': usn,
        'friendlyName': friendlyName,
        'descriptionURL': descriptionURL,
        'manufacturer': manufacturer,
        'serviceType': serviceType,
        'controlURL': controlURL,
        'eventSubURL': eventSubURL,
        'scpdURL': scpdURL,
        'presentationURL': presentationURL,
      };

  factory UpnpDevice.newDevice({
    required String usn,
    required String friendlyName,
    required String descriptionURL,
    String? serviceType,
    String? controlURL,
    String? manufacturer,
    String? eventSubURL,
    String? scpdURL,
    String? presentationURL,
    String? description,
    bool isConnected = false,
  }) {
    return UpnpDevice(
      id: -1,
      usn: usn,
      friendlyName: friendlyName,
      descriptionURL: descriptionURL,
      controlURL: controlURL,
      manufacturer: manufacturer,
      serviceType: serviceType,
      eventSubURL: eventSubURL,
      scpdURL: scpdURL,
      presentationURL: presentationURL,
      isConnected: isConnected,
    );
  }

  @override
  String toString() => 'UpnpDevice id: $id, '
      'friendlyName: $friendlyName, '
      'USN: $usn, controlURL: $controlURL'
      'manufacturer: $manufacturer, serviceType: $serviceType, ';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpnpDevice && other.usn == usn;
  }

  @override
  int get hashCode => usn.hashCode;

  UpnpDevice copyWith({required bool isConnected}) {
    return UpnpDevice(
      id: id,
      usn: usn,
      friendlyName: friendlyName,
      descriptionURL: descriptionURL,
      controlURL: controlURL,
      manufacturer: manufacturer,
      serviceType: serviceType,
      eventSubURL: eventSubURL,
      scpdURL: scpdURL,
      presentationURL: presentationURL,
      isConnected: isConnected,
    );
  }
}

// 扩展方法用于 UpnpDevice 和 UpnpDeviceModelCompanion 的互转换
