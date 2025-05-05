import 'dart:ffi';
import 'dart:io';

DynamicLibrary? loadLibrary(String lib) {
  // Load the shared library
  DynamicLibrary? tvLibrary;
  try {
    if (Platform.isAndroid || Platform.isIOS) {
      tvLibrary = DynamicLibrary.open("lib$lib.so");
    } else if (Platform.isMacOS) {
      tvLibrary = DynamicLibrary.open("lib$lib.dylib");
    } else if (Platform.isLinux) {
      tvLibrary = DynamicLibrary.open("lib$lib.so");
    } else if (Platform.isWindows) {
      tvLibrary = DynamicLibrary.open('$lib.dll');
    } else {
      throw UnsupportedError(
          'Unsupported platform: ${Platform.operatingSystem}');
    }
  } catch (e) {
    tvLibrary = null;
  }
  return tvLibrary;
}
