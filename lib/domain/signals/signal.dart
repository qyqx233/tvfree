import 'package:signals/signals_flutter.dart';

final networkAddressSignal = signal<String?>(null, autoDispose: false);
final parseM3U8EndpointSignal = signal<String?>(null, autoDispose: false);
final m3u8SkSignal = signal<String?>(null, autoDispose: false);
