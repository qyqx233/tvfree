import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tvfree/data/repository/kv.dart';
import 'package:tvfree/data/repository/m3u8_parser_impl.dart';
import 'package:tvfree/objectbox.g.dart';

import 'data/repository/upnp_impl.dart';
import 'presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // final dir = await getApplicationDocumentsDirectory();
  // final db = Database('${dir.path}/todos.db');
  // final todosRepository = UpnpRepositoryImpl(db);
  final appDir = await getApplicationDocumentsDirectory();
  final store = await openStore(directory: '${appDir.path}/objectbox');
  runApp(TvFreeApp(
    upnpsRepository: UpnpRepositoryImpl(store),
    m3u8parserRepository: M3u8ParserRepositoryImpl(store),
    kvRepository: KvRepositoryImpl(store),
  ));
}
