import 'dart:async';

import 'package:tvfree/domain/model/kv.dart';
import 'package:tvfree/domain/repository/kvs.dart';
import 'package:tvfree/objectbox.g.dart';

final keyUpnpActived = "upnp";

class KvRepositoryImpl implements KvRepository {
  final Store database;

  KvRepositoryImpl(this.database);

  @override
  Future<int> add(Kv kv) async {
    final id = database.box<Kv>().put(kv);
    return id;
  }

  @override
  Future<String?> getByKey(String key) async {
    final query = database.box<Kv>().query(Kv_.key.equals(key)).build();
    final result = query.findFirst();
    query.close();
    return result?.value;
  }

  @override
  Future<bool> removeByKey(String key) async {
    final box = database.box<Kv>();
    final query = box.query(Kv_.key.equals(key)).build();
    final result = query.findFirst();
    if (result != null) {
      box.remove(result.id);
      query.close();
      return true;
    }
    query.close();
    return false;
  }
}
