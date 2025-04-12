// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:tvfree/domain/model/device.dart';
import 'package:tvfree/internal/util/http.dart';
import 'package:xml/xml.dart' as xml;

Map<String, String> parseSsdpHeaders(String response) {
  final headers = <String, String>{};
  final lines = response.split('\r\n');

  for (final line in lines) {
    if (line.contains(':')) {
      final index = line.indexOf(':');
      final key = line.substring(0, index).trim().toUpperCase();
      final value = line.substring(index + 1).trim();
      headers[key] = value;
    }
  }

  return headers;
}

extension RawDatagramSocketExt on RawDatagramSocket {
  /// 异步接收一个数据报，支持超时
  Future<Datagram?> receiveDatagram(Duration timeout) async {
    final completer = Completer<Datagram?>();
    late StreamSubscription<RawSocketEvent> sub;
    Timer? timer;

    sub = listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = receive();
        if (datagram != null) {
          sub.cancel(); // 取消监听
          timer?.cancel(); // 取消超时
          completer.complete(datagram);
        }
      }
    });

    // 设置超时
    timer = Timer(timeout, () {
      sub.cancel();
      completer.complete(null);
    });

    return completer.future;
  }
}

class UpnpDeviceDetector {
  static Future<UpnpDevice?> testUpnp(String ip) async {
    try {
      final device = await UpnpDeviceDetector.checkMediaRendererSupport(ip);
      if (device == null) return null;
      final device2 = await UpnpDeviceDetector.parseDescription(device);
      if (device2 == null) return null;
      return device2;
    } catch (e) {
      return null;
    }
  }

  static Future<UpnpDevice?> checkMediaRendererSupport(String targetIp,
      {int port = 1900, Duration timeout = const Duration(seconds: 2)}) async {
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final ssdpRequest = "M-SEARCH * HTTP/1.1\r\n"
          "HOST: 239.255.255.250:$port\r\n"
          "MAN: \"ssdp:discover\"\r\n"
          "MX: 1\r\n"
          "ST: urn:schemas-upnp-org:device:MediaRenderer:1\r\n"
          "\r\n";
      final data = utf8.encode(ssdpRequest);
      socket.send(data, InternetAddress(targetIp), port);
      final datagram = await socket.receiveDatagram(timeout);
      if (datagram == null) {
        return null;
      }
      final response = utf8.decode(datagram.data, allowMalformed: true);
      if (response.contains('urn:schemas-upnp-org:device:MediaRenderer:1')) {
        final map = parseSsdpHeaders(response);
        final location = map["LOCATION"];
        final usn = map["USN"] as String;
        if (location != null && location.isNotEmpty) {
          return UpnpDevice(
              id: -1,
              usn: getUSN(usn),
              friendlyName: "",
              descriptionURL: location);
        }
      }
      return null;
    } finally {
      socket?.close();
    }
  }

  static String getUSN(String s) {
    final usn =
        s.split(' ').firstWhere((element) => element.startsWith('uuid'));
    final index = usn.indexOf('::');
    if (index != -1) {
      return usn.substring(0, index);
    }
    return usn;
  }

  static Future<UpnpDevice?> parseDescription(UpnpDevice upnpDevice) async {
    final descriptionURL = upnpDevice.descriptionURL;
    try {
      final uri = Uri.parse(descriptionURL);
      var urlBase =
          '${uri.scheme}://${uri.host}${uri.port != 0 ? ':${uri.port}' : ''}';
      final descriptionXml = await Http.fetchString(descriptionURL);
      if (descriptionXml == null) {
        return null;
      }
      final document = xml.XmlDocument.parse(descriptionXml);
      final deviceElement = document.findAllElements('device').first;
      final friendlyName =
          deviceElement.getElement('friendlyName')?.innerText ?? 'Unknown';
      final manufacturer =
          deviceElement.getElement('manufacturer')?.innerText ?? 'Unknown';
      final avTransportService = deviceElement
          .findAllElements('service')
          .firstWhere((service) =>
              service.getElement('serviceType')?.innerText ==
              'urn:schemas-upnp-org:service:AVTransport:1');
      final controlUrlPath =
          avTransportService.getElement('controlURL')?.innerText ?? '';
      urlBase = document.getElement('URLBase')?.innerText ?? urlBase;
      final fullControlUrl = urlBase +
          (!urlBase.endsWith('/') && !controlUrlPath.startsWith('/')
              ? '/'
              : '') +
          controlUrlPath;
      return UpnpDevice(
          friendlyName: friendlyName,
          usn: upnpDevice.usn,
          descriptionURL: descriptionURL,
          controlURL: fullControlUrl,
          serviceType: avTransportService.getElement('serviceType')?.innerText,
          eventSubURL: avTransportService.getElement('eventSubURL')?.innerText,
          scpdURL: avTransportService.getElement('SCPDURL')?.innerText,
          presentationURL:
              avTransportService.getElement('presentationURL')?.innerText,
          manufacturer: manufacturer);
    } catch (e) {
      return null;
    }
  }
}
