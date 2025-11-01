import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:tvfree/data/repository/kv.dart';
import 'package:tvfree/data/repository/m3u8_parser_impl.dart';
import 'package:tvfree/data/repository/upnp_impl.dart';
import 'package:tvfree/domain/repository/kvs.dart';
import 'package:tvfree/domain/repository/m3u8s.dart';
import 'package:tvfree/domain/repository/upnps.dart';
import 'package:tvfree/domain/usecase/control_device.dart';
import 'package:tvfree/domain/usecase/crud_device.dart';
import 'package:tvfree/domain/usecase/m3u8_parser.dart';
import 'di.config.dart';
import 'objectbox.g.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init', // default
  preferRelativeImports: true, // default
  asExtension: true, // default
)
Future<void> configureDependencies() async {
  getIt.init();
}

Store? _store;
void setStore(Store store) {
  _store = store;
}

@module
abstract class DIModule {
  @singleton
  M3u8ParserRepository get m3u8ParserRepository =>
      M3u8ParserRepositoryImpl(_store!);

  @singleton
  UpnpRepository get upnpRepository => UpnpRepositoryImpl(_store!);

  @singleton
  KvRepository get kvRepository => KvRepositoryImpl(_store!);

  @singleton
  CrudDevice get crudDevice => CrudDevice(upnpRepository, kvRepository);

  @singleton
  M3u8ParserService get m3u8ParserService =>
      M3u8ParserService(m3u8ParserRepository);

  @singleton
  ControlDevice get controlDevice => ControlDevice(upnpRepository);
}
