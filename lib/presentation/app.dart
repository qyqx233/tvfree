import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // 引入 go_router
import 'package:tvfree/data/repository/kv.dart';
import 'package:tvfree/domain/repository/m3u8s.dart';
import 'package:tvfree/domain/usecase/control_device.dart';
import 'package:tvfree/domain/usecase/crud_device.dart';
import 'package:tvfree/domain/usecase/m3u8_parser.dart';
import 'package:tvfree/presentation/viewmodel/m3u8_parser.dart'; // 导入M3u8ParserVM
import 'package:tvfree/presentation/views/m3u8_parser.dart'; // 导入M3u8ParserView
import 'package:tvfree/presentation/views/resource.dart';

import '../domain/repository/upnps.dart';
import 'viewmodel/device_list.dart';
import 'views/device_list.dart';

class TvFreeApp extends StatelessWidget {
  const TvFreeApp({
    super.key,
    required this.upnpsRepository,
    required this.m3u8parserRepository,
    required this.kvRepository,
  });

  final UpnpRepository upnpsRepository;
  final M3u8ParserRepository m3u8parserRepository;
  final KvRepositoryImpl kvRepository;

  @override
  Widget build(BuildContext context) {
    final controlDevice = ControlDevice(upnpsRepository);
    final router = GoRouter(
      initialLocation: '/upnp',
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            return Scaffold(
              body: child,
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _getNavIndex(state.matchedLocation),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.devices),
                    label: '投屏设备',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.video_library),
                    label: '解析',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.cloud),
                    label: '资源',
                  ),
                ],
                onTap: (index) {
                  if (index == 0) {
                    context.go('/upnp');
                  } else if (index == 1) {
                    context.go('/parser');
                  } else if (index == 2) {
                    context.go('/remote');
                  }
                },
              ),
            );
          },
          routes: [
            GoRoute(
              path: '/upnp',
              builder: (context, state) => DeviceListView(
                viewModel: DeviceListVM(
                  crudDevice: CrudDevice(upnpsRepository, kvRepository),
                  controlDevice: controlDevice,
                ),
              ),
            ),
            GoRoute(
                path: '/parser',
                builder: (context, state) => M3u8ParserView(
                      viewModel: M3u8ParserVM(
                        M3u8ParserService(m3u8parserRepository),
                        CrudDevice(upnpsRepository, kvRepository),
                        controlDevice,
                      ),
                    )),
            GoRoute(
              path: '/remote',
              builder: (context, state) => RemoteResourceView(),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'Upnp Devices',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }

  // 根据当前路径获取导航栏索引
  int _getNavIndex(String location) {
    if (location.startsWith('/upnp')) return 0;
    if (location.startsWith('/parser')) return 1;
    if (location.startsWith('/remote')) return 2;
    return 0; // 默认返回第一个选项
  }
}
