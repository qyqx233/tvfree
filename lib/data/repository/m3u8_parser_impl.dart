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
      return 0;
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
    return 1;
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
    return 1;
  }
}
