import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:tvfree/internal/dll/pub.dart';

// final DynamicLibrary? tvLibrary = null;
final DynamicLibrary? tvLibrary = loadLibrary("tv");

// 定义 Go 函数签名

// final FreeCString freeCString = myLibrary
//     .lookup<NativeFunction<FreeCStringFunc>>('FreeCString')
//     .asFunction();
typedef GetNameUrlJSONCFunc = Pointer<Utf8> Function(); // C function signature
typedef GetNameUrlJSONDartFunc = Pointer<Utf8>
    Function(); // Dart function signature

typedef FreeCStringCFunc = Void Function(Pointer<Utf8>); // C function signature
typedef FreeCStringDartFunc = void Function(
    Pointer<Utf8>); // Dart function signature

// Get the functions
// GetNameUrlJSONDartFunc getNameUrlJSON = tvLibrary
//     .lookup<NativeFunction<GetNameUrlJSONCFunc>>('GetNameUrlJSON')
//     .asFunction<GetNameUrlJSONDartFunc>();

// FreeCStringDartFunc freeCString = tvLibrary
//     .lookup<NativeFunction<FreeCStringCFunc>>('FreeCString')
//     .asFunction<FreeCStringDartFunc>();

GetNameUrlJSONDartFunc? getNameUrlJSON = tvLibrary
    ?.lookup<NativeFunction<GetNameUrlJSONCFunc>>('GetNameUrlJSON')
    .asFunction<GetNameUrlJSONDartFunc>();

FreeCStringDartFunc? freeCString = tvLibrary
    ?.lookup<NativeFunction<FreeCStringCFunc>>('FreeCString')
    .asFunction<FreeCStringDartFunc>();
