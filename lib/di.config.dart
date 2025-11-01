// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import 'di.dart' as _i913;
import 'domain/repository/kvs.dart' as _i353;
import 'domain/repository/m3u8s.dart' as _i216;
import 'domain/repository/upnps.dart' as _i934;
import 'domain/usecase/control_device.dart' as _i688;
import 'domain/usecase/crud_device.dart' as _i737;
import 'domain/usecase/m3u8_parser.dart' as _i692;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final dIModule = _$DIModule();
    gh.singleton<_i216.M3u8ParserRepository>(
        () => dIModule.m3u8ParserRepository);
    gh.singleton<_i934.UpnpRepository>(() => dIModule.upnpRepository);
    gh.singleton<_i353.KvRepository>(() => dIModule.kvRepository);
    gh.singleton<_i737.CrudDevice>(() => dIModule.crudDevice);
    gh.singleton<_i692.M3u8ParserService>(() => dIModule.m3u8ParserService);
    gh.singleton<_i688.ControlDevice>(() => dIModule.controlDevice);
    return this;
  }
}

class _$DIModule extends _i913.DIModule {}
