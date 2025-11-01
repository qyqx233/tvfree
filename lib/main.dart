import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tvfree/domain/repository/kvs.dart';
import 'package:tvfree/domain/repository/m3u8s.dart';
import 'package:tvfree/domain/repository/upnps.dart';
import 'package:tvfree/objectbox.g.dart';
import 'package:tvfree/di.dart';
import 'presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // final dir = await getApplicationDocumentsDirectory();
  // final db = Database('${dir.path}/todos.db');
  // final todosRepository = UpnpRepositoryImpl(db);
  final appDir = await getApplicationDocumentsDirectory();
  setStore(await openStore(directory: '${appDir.path}/objectbox'));
  await configureDependencies();
  runApp(TvFreeApp(
    upnpsRepository: getIt<UpnpRepository>(),
    m3u8parserRepository: getIt<M3u8ParserRepository>(),
    kvRepository: getIt<KvRepository>(),
  ));
}
