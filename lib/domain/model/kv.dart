import 'package:objectbox/objectbox.dart';

@Entity()
class Kv {
  @Id()
  int id = 0; // 主键 ID

  @Index() // 为 key 字段添加索引
  String? key;

  String? value;

  Kv({
    this.key,
    this.value,
  });
}
