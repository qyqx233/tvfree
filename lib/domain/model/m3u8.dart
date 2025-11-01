import 'package:objectbox/objectbox.dart';

@Entity()
class M3u8ParseHistory {
  @Id()
  int id = 0;
  String? url;
  String? result;
  DateTime? createdAt;

  M3u8ParseHistory({
    this.id = 0,
    this.url,
    this.result,
    required this.createdAt,
  });
}

@Entity()
class M3u8Parser {
  @Id()
  int id = 0;

  String? name;
  String? url;
  String? sk;
  bool isActive = false;

  M3u8Parser({
    this.id = 0,
    this.name,
    this.url,
    this.sk,
    this.isActive = false,
  });

  factory M3u8Parser.fromJson(Map<String, dynamic> json) => M3u8Parser(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String?,
        url: json['url'] as String?,
        sk: json['sk'] as String?,
        isActive: json['isActive'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        if (id != 0) 'id': id,
        'name': name,
        'url': url,
        'sk': sk,
        'isActive': isActive,
      };

  factory M3u8Parser.newParser({
    String? name,
    String? url,
    String? sk,
    bool isActive = false,
  }) {
    return M3u8Parser(
      id: 0,
      name: name,
      url: url,
      sk: sk,
      isActive: isActive,
    );
  }

  @override
  String toString() => 'M3u8Parser id: $id, '
      'name: $name, '
      'url: $url, '
      'sk: $sk, '
      'isActive: $isActive';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is M3u8Parser &&
        other.url == url &&
        other.name == name &&
        other.sk == sk &&
        other.isActive == isActive;
  }

  @override
  int get hashCode => Object.hash(url, name, sk, isActive);

  M3u8Parser copyWith({
    String? name,
    String? url,
    String? sk,
    bool? isActive,
  }) {
    return M3u8Parser(
      id: id,
      name: name ?? this.name,
      url: url ?? this.url,
      sk: sk ?? this.sk,
      isActive: isActive ?? this.isActive,
    );
  }
}
