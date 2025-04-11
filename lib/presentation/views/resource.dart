import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

class RemoteResourceView extends StatefulWidget {
  const RemoteResourceView({super.key});

  @override
  _RemoteResourceViewState createState() => _RemoteResourceViewState();
}

class _RemoteResourceViewState extends State<RemoteResourceView>
    with SignalsMixin {
  late final counter = createSignal(0);
  late final isEven = createComputed(() => counter.value.isEven);
  late final isOdd = createComputed(() => counter.value.isOdd);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Counter: even=$isEven, odd=$isOdd'),
            ElevatedButton(
              onPressed: () => counter.value++,
              child: Text('Increment'),
            ),
          ],
        ),
      ),
    );
  }
}
