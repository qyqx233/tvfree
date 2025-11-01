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
    // 如果 kv.id 为 0，说明是新对象，尝试查找是否已有相同 key 的记录
    if (kv.id == 0 && kv.key != null) {
      final query = database.box<Kv>().query(Kv_.key.equals(kv.key!)).build();
      final existing = query.findFirst();
      query.close();
      
      if (existing != null) {
        // 如果找到了 existing 记录，则更新它而不是创建新记录
        kv.id = existing.id;
      }
    }
    
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
