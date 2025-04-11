import 'package:tvfree/domain/model/m3u8.dart';
import 'package:tvfree/domain/repository/m3u8s.dart';

class M3u8ParserService {
  final M3u8ParserRepository _repo;
  M3u8ParserService(this._repo);
  Future<int> update(M3u8Parser parser) async {
    return await _repo.update(parser);
  }

  Future<M3u8Parser?> search(String url) async {
    return _repo.search(url);
  }

  Future<void> remove(M3u8Parser device) async {
    await _repo.remove(device);
  }

  Future<List<M3u8Parser>> getAll() async {
    return await _repo.getAll();
  }

  Future<M3u8Parser?> get(int id) async {
    return await _repo.get(id);
  }

  Future<int> add(M3u8Parser parser) async {
    return await _repo.add(parser);
  }
}
