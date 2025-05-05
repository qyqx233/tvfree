import 'dart:async';

extension SafeConvertExtension<T> on Stream<T> {
  Stream<E?> safeMap<E>(FutureOr<E> Function(T) convert) {
    return asyncMap((event) async {
      return await safeConvert(event, convert);
    });
  }
}

FutureOr<E?> safeConvert<T, E>(T event, FutureOr<E> Function(T) convert) async {
  try {
    return await convert(event);
  } catch (e) {
    return null;
  }
}

class Streams {
  /// 并发处理函数（泛型版本）
  /// - [T]: 输入数据类型
  /// - [R]: 返回结果类型
  /// - [dataList]: 待处理的数据列表
  /// - [process]: 异步处理函数（必须返回 `Future<R>`）
  /// - [maxConcurrency]: 最大并发数（通过 Stream 控制）
  static Future<List<R?>> concurrent<T, R>({
    required List<T> dataList,
    required Future<R?> Function(T) process,
    int maxConcurrency = 20,
  }) async {
    if (dataList.isEmpty) return [];
    final results = <R?>[];

    // 使用原子变量来跟踪当前索引
    int currentIndex = 0;

    final tasks = <Future<void>>[];
    Future<void> worker(int id) async {
      while (true) {
        // 安全地获取并递增索引
        int index = dataList.length;
        synchronized(() {
          if (currentIndex < dataList.length) {
            index = currentIndex++;
          }
        });
        if (index >= dataList.length) break;
        try {
          final result = await process(dataList[index]);
          // if (result != null) {
          synchronized(() {
            results.add(result);
          });
          // }
        } catch (e) {
          // 处理异常
        }
      }
    }

    for (int i = 0; i < maxConcurrency; i++) {
      tasks.add(worker(i));
    }
    await Future.wait(tasks);
    return results;
  }
}

// 一个简单的同步函数，确保线程安全
void synchronized(void Function() fn) {
  fn();
}

class StreamsOld {
  /// 并发处理函数（泛型版本）
  /// - [T]: 输入数据类型
  /// - [R]: 返回结果类型
  /// - [dataList]: 待处理的数据列表
  /// - [processData]: 异步处理函数（必须返回 `Future<R>`）
  /// - [maxConcurrency]: 最大并发数（通过 Stream 控制）
  static Future<List<R>> concurrent<T, R>({
    required List<T> dataList,
    required Future<R?> Function(T) process,
    int maxConcurrency = 20,
  }) async {
    final controller = StreamController<T>();
    final results = <R>[];

    final subscription = controller.stream
        .asyncMap(process) // 直接使用传入的 processData 函数
        .listen((result) {
      if (result != null) results.add(result);
    });

    for (final data in dataList) {
      controller.add(data);
    }

    // 等待所有任务完成
    await controller.close();
    await subscription.asFuture();
    return results;
  }

  /// 并发处理函数（泛型版本）
  /// - [T]: 输入数据类型
  /// - [R]: 返回结果类型
  /// - [dataList]: 待处理的数据列表
  /// - [processData]: 异步处理函数（必须返回 `Future<R>`）
  /// - [maxConcurrency]: 最大并发数
  static Future<List<R>> process<T, R>({
    required List<T> dataList,
    required Future<R?> Function(T) processData,
    int maxConcurrency = 20,
  }) async {
    final results = <R>[];
    // 对数据列表分批处理，每批最多maxConcurrency个任务
    for (int i = 0; i < dataList.length; i += maxConcurrency) {
      final end = (i + maxConcurrency < dataList.length)
          ? i + maxConcurrency
          : dataList.length;

      // 创建这一批的Future任务
      final batch = dataList.sublist(i, end).map((data) async {
        try {
          final result = await processData(data);
          if (result != null) {
            results.add(result);
          }
        } catch (_) {}
      }).toList();
      await Future.wait(batch);
    }
    return results;
  }
}
