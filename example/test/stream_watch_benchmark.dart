// ignore_for_file: avoid_print

import 'dart:io';

import 'package:context_watch/context_watch.dart';
import 'package:example/benchmark_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Run this with `flutter run --release test/stream_watch_benchmark.dart`
main() async {
  assert(false); // fail in debug mode
  await benchmarkWidgets((WidgetTester tester) async {
    final timers = {
      'Stream.watch(context)': Stopwatch(),
      'StreamBuilder': Stopwatch(),
    };
    Future<void> benchmark({
      required String name,
      required bool useValueStream,
    }) async {
      await tester.pumpWidget(
        ContextWatchRoot(
          key: Key(name),
          child: MaterialApp(
            home: BenchmarkScreen(
              useValueStream: useValueStream,
              useStreamBuilder: name == 'StreamBuilder',
              runOnStart: false,
              showPerformanceOverlay: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start')));
      await tester.pumpAndSettle();
      LiveTestWidgetsFlutterBinding.instance.framePolicy =
          LiveTestWidgetsFlutterBindingFramePolicy.benchmark;
      timers[name]!.start();
      for (int i = 0; i < 100000; i++) {
        await tester.pumpBenchmark(Duration.zero);
      }
      timers[name]!.stop();
      LiveTestWidgetsFlutterBinding.instance.framePolicy =
          LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
      await tester.tap(find.byKey(const Key('stop')));
      await tester.pumpAndSettle();
    }

    await benchmark(
      name: 'Stream.watch(context)',
      useValueStream: false,
    );
    await benchmark(
      name: 'StreamBuilder',
      useValueStream: false,
    );
    await benchmark(
      name: 'Stream.watch(context)',
      useValueStream: false,
    );
    await benchmark(
      name: 'StreamBuilder',
      useValueStream: false,
    );

    final contextWatchTime =
        timers['Stream.watch(context)']!.elapsedMilliseconds;
    final streamBuilderTime = timers['StreamBuilder']!.elapsedMilliseconds;

    print('Stream.watch(context): ${contextWatchTime}ms');
    print('StreamBuilder: ${streamBuilderTime}ms');

    final results = [
      ('Stream.watch(context)', contextWatchTime),
      ('StreamBuilder', streamBuilderTime),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    final (fasterName, fasterTime) = results.first;
    final (slowerName, slowerTime) = results.last;
    final fasterPercent =
        ((1 - fasterTime / slowerTime) * 100).toStringAsFixed(2);
    final slowerPercent =
        ((slowerTime / fasterTime - 1) * 100).toStringAsFixed(2);
    print('$fasterName is $fasterPercent% faster than $slowerName');
    print('$slowerName is $slowerPercent% slower than $fasterName');
  });
  exit(0);
}
