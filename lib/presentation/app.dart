import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // 引入 go_router
import 'package:tvfree/di.dart';
import 'package:tvfree/domain/model/m3u8.dart';
import 'package:tvfree/domain/repository/kvs.dart';
import 'package:tvfree/domain/repository/m3u8s.dart';
import 'package:tvfree/domain/repository/upnps.dart';
import 'package:tvfree/domain/signals/signals.dart';
import 'package:tvfree/domain/usecase/control_device.dart';
import 'package:tvfree/domain/usecase/crud_device.dart';
import 'package:tvfree/domain/usecase/m3u8_parser.dart';
import 'package:tvfree/presentation/viewmodel/device_list.dart';
import 'package:tvfree/presentation/viewmodel/m3u8_parser.dart'; // 导入M3u8ParserVM
import 'package:tvfree/presentation/viewmodel/resource.dart';
import 'package:tvfree/presentation/viewmodel/settings.dart';
import 'package:tvfree/presentation/views/device_list.dart';
import 'package:tvfree/presentation/views/m3u8_parser.dart'; // 导入M3u8ParserView
import 'package:tvfree/presentation/views/resource.dart';
import 'package:tvfree/presentation/views/settings.dart';

class TvFreeApp extends StatefulWidget {
  const TvFreeApp({
    super.key,
    required this.upnpsRepository,
    required this.m3u8parserRepository,
    required this.kvRepository,
  });

  final UpnpRepository upnpsRepository;
  final M3u8ParserRepository m3u8parserRepository;
  final KvRepository kvRepository;

  @override
  State<TvFreeApp> createState() => _TvFreeAppState();
}

class _TvFreeAppState extends State<TvFreeApp> {
  late final M3u8ParserService _m3u8ParserService;
  StreamSubscription<List<M3u8Parser>>? _parserSubscription;
  M3u8Parser? _activeParser;

  @override
  void initState() {
    super.initState();
    _m3u8ParserService = M3u8ParserService(widget.m3u8parserRepository);
    _loadActiveParser();
    _setupParserWatcher();
  }

  Future<void> _loadActiveParser() async {
    try {
      final allParsers = await _m3u8ParserService.getAll();
      if (allParsers.isNotEmpty) {
        _activeParser = allParsers.firstWhere(
          (parser) => parser.isActive,
          orElse: () => allParsers.first,
        );
      } else {
        _activeParser = null;
      }
      _updateParserSignals();
    } catch (e) {
      _activeParser = null;
      _updateParserSignals();
    }
  }

  void _updateParserSignals() {
    if (_activeParser != null) {
      parseM3U8EndpointSignal.value = _activeParser!.url ?? '';
      m3u8SkSignal.value = _activeParser!.sk;
    } else {
      parseM3U8EndpointSignal.value = '';
      m3u8SkSignal.value = null;
    }
  }

  void _setupParserWatcher() {
    _parserSubscription = _m3u8ParserService.watchAll().listen((parsers) {
      // 当解析器列表发生变化时，重新加载活跃解析器
      if (kDebugMode) {
        debugPrint('解析器列表发生变化，重新加载活跃解析器');
      }
      _loadActiveParser();
    });
  }

  @override
  void dispose() {
    _parserSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var _ = ResourceVM(getIt<CrudDevice>(), getIt<ControlDevice>());
    final router = GoRouter(
      initialLocation: '/upnp',
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            return Scaffold(
              body: child,
              bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: _getNavIndex(state.matchedLocation),
                selectedItemColor: Theme.of(context).colorScheme.primary,
                unselectedItemColor: Colors.grey,
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
                  BottomNavigationBarItem(
                      icon: Icon(Icons.settings), label: "设置")
                ],
                onTap: (index) {
                  if (index == 0) {
                    context.go('/upnp');
                  } else if (index == 1) {
                    context.go('/parser');
                  } else if (index == 2) {
                    context.go('/remote');
                  } else if (index == 3) {
                    context.go("/settings");
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
                  crudDevice: getIt<CrudDevice>(),
                  controlDevice: getIt<ControlDevice>(),
                ),
              ),
            ),
            GoRoute(
                path: '/parser',
                builder: (context, state) {
                  return M3u8ParserView(
                    viewModel: M3u8ParserVM(
                      getIt<CrudDevice>(),
                      getIt<ControlDevice>(),
                    ),
                  );
                }),
            GoRoute(
              path: '/remote',
              builder: (context, state) => ResourceView(
                viewModel: ResourceVM(
                  getIt<CrudDevice>(),
                  getIt<ControlDevice>(),
                ),
              ),
            ),
            GoRoute(
                path: "/settings",
                builder: (context, state) {
                  return SettingsView(
                    viewModel:
                        SettingsVM(widget.kvRepository, _m3u8ParserService),
                  );
                })
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
    if (location.startsWith('/settings')) return 3;
    return 0; // 默认返回第一个选项
  }
}
