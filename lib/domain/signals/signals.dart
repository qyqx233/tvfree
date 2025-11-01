import 'package:signals/signals_flutter.dart';

final networkAddressSignal = signal<String?>(null, autoDispose: false);
final parseM3U8EndpointSignal = signal<String>('', autoDispose: false);
final m3u8SkSignal = signal<String?>(null, autoDispose: false);

final remoteStorageUrl = signal<String>('', autoDispose: false);

final remoteStorageApiKey = signal<String>('', autoDispose: false);
final remoteStorageEnabled = signal<bool>(false, autoDispose: false);
