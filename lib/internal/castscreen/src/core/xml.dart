import 'package:xml/xml.dart';
import 'package:xml/xpath.dart'; // 导入 xpath 扩展

void addUrlBaseIfMissingUsing(XmlDocument doc, String urlValue) {
  final urlBaseNodes = doc.xpathEvaluate('/root/URLBase').nodes.toList();
  if (urlBaseNodes.isNotEmpty) {
    if (urlBaseNodes[0].innerText.trim().isEmpty) {
      urlBaseNodes[0].innerText = urlValue;
    }
  } else {
    final newElement = XmlElement(XmlName('URLBase'));
    final newTextNode = XmlText(urlValue);
    newElement.children.add(newTextNode);
    doc.xpathEvaluate('/root').nodes.first.children.add(newElement);
  }
}

String getHostPort(String url) {
  final uri = Uri.parse(url);
  return '${uri.scheme}://${uri.host}:${uri.port}';
}
