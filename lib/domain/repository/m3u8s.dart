import 'package:tvfree/domain/model/m3u8.dart';

abstract class M3u8ParserRepository {
  Future<List<M3u8Parser>> getAll();
  Future<M3u8Parser?> get(int id);
  Future<int> add(M3u8Parser device);
  Future<void> addMany(List<M3u8Parser> device);
  Future<M3u8Parser?> search(String url);
  Future<void> remove(M3u8Parser device);
  Future<int> update(M3u8Parser device);
}
