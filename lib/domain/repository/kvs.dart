import 'package:tvfree/domain/model/kv.dart';

abstract class KvRepository {
  Future<String?> getByKey(String key);
  Future<int> add(Kv kv);
  Future<bool> removeByKey(String key);
}
