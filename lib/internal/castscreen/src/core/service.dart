// ignore_for_file: avoid_print

/*
<service>
  <serviceType>urn:schemas-upnp-org:service:serviceType:v</serviceType>
  <serviceId>urn:upnp-org:serviceId:serviceID</serviceId>
  <SCPDURL>URL to service description</SCPDURL>
  <controlURL>URL for control</controlURL>
  <eventSubURL>URL for eventing</eventSubURL>
</service>
*/

// ignore_for_file: non_constant_identifier_names

part of 'lib.dart';

/// The device service controller
final class Service {
  /// The device service spec
  final ServiceSpec spec;
  Service._(this.spec);
  factory Service.build(ServiceSpec spec) {
    return Service._(spec);
  }

  late Map<String, ActionSpec> actionsMap;

  Future<void> _init() async {
    spec.actionList = <ActionSpec>[];
    actionsMap = <String, ActionSpec>{};
    final resp = await Http.get(spec.scpdReqURL, ScpdServiceSpec.fromXml);
    spec.actionList.addAll(resp.data.actionList);
    for (var actionSpec in spec.actionList) {
      actionsMap[actionSpec.name] = actionSpec;
    }
  }

  Future<void> _init2() async {
    spec.actionList = <ActionSpec>[];
    actionsMap = <String, ActionSpec>{};
    final resp = await Http.get(spec.scpdReqURL, ScpdServiceSpec.fromXml);
    spec.actionList.addAll(resp.data.actionList);
    for (var actionSpec in spec.actionList) {
      actionsMap[actionSpec.name] = actionSpec;
    }
    // print('>>>>>> Service._init2: $actionsMap ${resp.data.actionList}');
  }

  /// Invoke a service action, and returns a generics type
  Future<OUTPUT> invoke<INPUT, OUTPUT>(
    String action,
    INPUT input,
    Map<String, String> Function(INPUT input) inputConvertor,
    OUTPUT Function(Map<String, String>) outputConvertor,
  ) async {
    final xmlBody = _buildXml(action, inputConvertor(input));
    final resp = await Http.post(
      spec.controlReqURL,
      // 'http://192.168.5.24:38400/MediaServer/rendererdevicedesc.xml',
      (xml) => _parseXml(xml, action),
      body: xmlBody,
      headers: _headers(spec, action),
    );
    return Future.value(outputConvertor(resp.data));
  }

  /// Invoke a service action, and returns a map
  Future<Map<String, String>> invokeMap(
          String action, Map<String, String> input) async =>
      invoke<Map<String, String>, Map<String, String>>(
        action,
        input,
        (Map<String, String> m) => m,
        (Map<String, String> m) => m,
      );

  String _buildXml(String action, Map<String, String> arguments) {
    final xb = XmlBuilder();
    arguments['CurrentURIMetaData'] =
        'lt;DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/"&gt;&lt;item id="123" parentID="-1" restricted="1"&gt;&lt;res protocolInfo="http-get:*:video/*:*;DLNA.ORG_OP=01;DLNA.ORG_FLAGS=01700000000000000000000000000000"&gt;http://videong.skzic.cn/20190412/K7FXYvig/1622kb/hls/index.m3u8?wsSecret=e183cce42f0a622236cb29b5122990da&amp;amp;wsTime=1596287955&lt;/res&gt;&lt;upnp:storageMedium&gt;UNKNOWN&lt;/upnp:storageMedium&gt;&lt;upnp:writeStatus&gt;UNKNOWN&lt;/upnp:writeStatus&gt;&lt;dc:title&gt;01&lt;/dc:title&gt;&lt;upnp:class&gt;object.item.videoItem&lt;/upnp:class&gt;&lt;/item&gt;&lt;/DIDL-Lite&gt;';
    arguments['InstanceID'] = '0';
    xb.processing('xml', 'version="1.0"');
    xb.element('s:Envelope', nest: () {
      xb.attribute('xmlns:s', 'http://schemas.xmlsoap.org/soap/envelope/');
      xb.attribute(
          's:encodingStyle', 'http://schemas.xmlsoap.org/soap/encoding/');
      xb.element('s:Body', nest: () {
        xb.element('u:$action', nest: () {
          xb.attribute('xmlns:u', spec.serviceType);
          arguments.forEach((k, v) {
            xb.element(k, nest: v);
          });
        });
      });
    });
    return xb.buildDocument().toXmlString();
  }

  Map<String, String> _parseXml(XmlDocument xml, String action) {
    // print('>>>> parse xml: ${xml.toXmlString()}, $actionsMap, $action');
    final outArgs =
        actionsMap[action]!.argumentList.where((arg) => arg.direction == 'out');
    final m = <String, String>{};
    for (var arg in outArgs) {
      m[arg.name] = xml.xpathEvaluate(_xpath(action, arg.name)).string;
    }
    return m;
  }

  static Map<String, String> _headers(ServiceSpec spec, String action) {
    return {
      "Content-Type": "text/xml; charset=utf-8",
      "SOAPAction": '"${spec.serviceType}#$action"'
    };
  }

  static String _xpath(String action, String argument) =>
      '/s:Envelope/s:Body/u:${action}Response/$argument/text()';
}

/// The device service spec.
final class ServiceSpec {
  /// The device base url
  final String URLBase;

  /// The urn of this services type
  final String serviceType;

  /// The urn of this services id
  final String serviceId;

  /// The url to control this service
  final String controlURL;

  /// The url this services description
  final String SCPDURL;

  /// The url to subscribe to events
  final String eventSubURL;

  /// The url to control req
  final String controlReqURL;

  /// The url to scpd req
  final String scpdReqURL;

  /// The device service action list
  late List<ActionSpec> actionList;

  ServiceSpec(
    this.URLBase,
    this.serviceType,
    this.serviceId,
    this.controlURL,
    this.SCPDURL,
    this.eventSubURL,
    this.controlReqURL,
    this.scpdReqURL,
  );

  /// The factory method fromXml
  factory ServiceSpec.fromXml(XmlDocument xml, int index) {
    final URLBase = xml.xpathEvaluate('/root/URLBase/text()').string;
    final serviceType = xml.xpathEvaluate(_xpath(index, 'serviceType')).string;
    final serviceId = xml.xpathEvaluate(_xpath(index, 'serviceId')).string;
    final controlURL = xml.xpathEvaluate(_xpath(index, 'controlURL')).string;
    final SCPDURL = xml.xpathEvaluate(_xpath(index, 'SCPDURL')).string;
    final eventSubURL = xml.xpathEvaluate(_xpath(index, 'eventSubURL')).string;
    final controlReqURL = URLBase +
        ((controlURL.endsWith('/') || controlURL.startsWith('/')) ? '' : '/') +
        controlURL;
    final scpdReqURL = URLBase +
        ((SCPDURL.endsWith('/') || SCPDURL.startsWith('/')) ? '' : '/') +
        SCPDURL;
    return ServiceSpec(
      URLBase,
      serviceType,
      serviceId,
      controlURL,
      SCPDURL,
      eventSubURL,
      controlReqURL,
      scpdReqURL,
    );
  }

  static String _xpath(int index, String name) =>
      '/root/device/serviceList/service[$index]/$name/text()';
}

final class ScpdServiceSpec {
  final List<ActionSpec> actionList;
  const ScpdServiceSpec(this.actionList);
  factory ScpdServiceSpec.fromXml(XmlDocument xml) {
    final length = xml.xpath('/scpd/actionList/action').length;
    return ScpdServiceSpec(
      List.generate(length, (index) => ActionSpec.fromXml(xml, index + 1)),
    );
  }
}
