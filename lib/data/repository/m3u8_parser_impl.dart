import 'dart:async';

import 'package:tvfree/domain/model/m3u8.dart';
import 'package:tvfree/domain/repository/m3u8s.dart';
import 'package:tvfree/objectbox.g.dart';

class M3u8ParserRepositoryImpl implements M3u8ParserRepository {
  final Store database;

  M3u8ParserRepositoryImpl(this.database);
  @override
  Future<int> add(M3u8Parser parser) async {
    final box = database.box<M3u8Parser>();
    final org = await search(parser.url!);
    if (org != null) {
      throw Exception('解析器已存在');
    }
    if (!parser.isActive) return box.put(parser);
    database.runInTransaction(
        TxMode.write,
        () => {
              box
                  .query(M3u8Parser_.isActive.equals(true))
                  .build()
                  .find()
                  .forEach((element) {
                element.isActive = false;
                box.put(element);
              }),
              box.put(parser),
            });
    return parser.id;
  }

  @override
  Future<void> addMany(List<M3u8Parser> parser) async {
    database.box<M3u8Parser>().putMany(parser);
  }

  @override
  Future<M3u8Parser?> get(int id) {
    throw UnimplementedError();
  }

  @override
  Future<List<M3u8Parser>> getAll() async {
    return database.box<M3u8Parser>().getAll();
  }

  @override
  Future<void> remove(M3u8Parser device) async {
    database.box<M3u8Parser>().remove(device.id);
  }

  @override
  Future<M3u8Parser?> search(String url) async {
    final query =
        database.box<M3u8Parser>().query(M3u8Parser_.url.equals(url)).build();
    final result = query.findFirst();
    query.close();
    return result;
  }

  @override
  Future<int> update(M3u8Parser parser) async {
    final box = database.box<M3u8Parser>();
    if (!parser.isActive) return box.put(parser);
    database.runInTransaction(
        TxMode.write,
        () => {
              box
                  .query(M3u8Parser_.isActive.equals(true))
                  .build()
                  .find()
                  .forEach((element) {
                element.isActive = false;
                box.put(element);
              }),
              box.put(parser),
            });
    return parser.id;
  }

  @override
  Stream<List<M3u8Parser>> watchAll() {
    final controller = StreamController<List<M3u8Parser>>.broadcast();
    List<M3u8Parser>? lastData;

    // 初始数据
    Future.microtask(() async {
      final parsers = database.box<M3u8Parser>().getAll();
      lastData = parsers;
      if (!controller.isClosed) {
        controller.add(parsers);
      }
    });

    // 定期检查数据变化
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (controller.isClosed) {
        timer.cancel();
        return;
      }

      final parsers = database.box<M3u8Parser>().getAll();

      // 只有当数据真正发生变化时才发送事件
      if (!_listsEqual(lastData, parsers)) {
        lastData = parsers;
        if (!controller.isClosed) {
          controller.add(parsers);
        }
      }
    });

    return controller.stream;
  }

  // 比较两个列表是否相等
  bool _listsEqual(List<M3u8Parser>? list1, List<M3u8Parser>? list2) {
    if (list1 == null && list2 == null) return true;
    if (list1 == null || list2 == null) return false;
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      if (!_parsersEqual(list1[i], list2[i])) {
        return false;
      }
    }
    return true;
  }

  // 比较两个解析器是否相等
  bool _parsersEqual(M3u8Parser parser1, M3u8Parser parser2) {
    return parser1.id == parser2.id &&
        parser1.url == parser2.url &&
        parser1.name == parser2.name &&
        parser1.isActive == parser2.isActive &&
        parser1.sk == parser2.sk;
  }
}
