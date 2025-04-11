import 'dart:io';

class NetAddr {
  static Future<List<String>> localIPv4MCastAddrs() async {
    try {
      // 获取所有网络接口
      List<NetworkInterface> ifaces = await NetworkInterface.list();
      // 存储符合条件的地址
      List<String> addrs = [];
      // 遍历所有网络接口
      for (NetworkInterface iface in ifaces) {
        // 检查接口是否支持多播、非回环且处于启动状态
        // 注意：Dart没有直接的Flag属性，所以我们基于接口名称判断回环
        if (iface.name.contains('lo')) {
          // 跳过回环接口
          continue;
        }
        // 遍历接口上的所有地址
        for (InternetAddress addr in iface.addresses) {
          // 只保留IPv4地址
          if (addr.type == InternetAddressType.IPv4) {
            if (addr.address.startsWith("10.")) continue;
            addrs.add(addr.address);
          }
        }
      }
      return addrs;
    } catch (err) {
      throw Exception('Error requesting host interfaces: $err');
    }
  }

  static List<String> getAllIPsInSubnet(String baseIp) {
    final subnet = baseIp.substring(0, baseIp.lastIndexOf('.'));
    final ips = <String>[];
    for (int i = 2; i <= 254; i++) {
      // 通常 .0 和 .255 保留
      ips.add('$subnet.$i');
    }
    return ips;
  }
}
