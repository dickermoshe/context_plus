import 'dart:async';

import 'package:context_watch/context_watch.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  testWidgets(
    'Stream.watch(context) gives new AsyncSnapshot after each stream event',
    (widgetTester) async {
      final streamController = StreamController<int>();
      final stream = streamController.stream;
      final snapshots = <AsyncSnapshot<int>>[];
      final widget = ContextWatchRoot(
        child: Builder(
          builder: (context) {
            final snapshot = stream.watch(context);
            snapshots.add(snapshot);
            return const SizedBox.shrink();
          },
        ),
      );
      await widgetTester.pumpWidget(widget);
      expect(snapshots, [
        const AsyncSnapshot.waiting(),
      ]);

      streamController.add(0);
      await widgetTester.pumpAndSettle();
      expect(snapshots, [
        const AsyncSnapshot.waiting(),
        const AsyncSnapshot.withData(ConnectionState.active, 0),
      ]);

      streamController.add(1);
      await widgetTester.pumpAndSettle();
      expect(snapshots, [
        const AsyncSnapshot.waiting(),
        const AsyncSnapshot.withData(ConnectionState.active, 0),
        const AsyncSnapshot.withData(ConnectionState.active, 1),
      ]);

      streamController.close();
      await widgetTester.pumpAndSettle();
      expect(snapshots, [
        const AsyncSnapshot.waiting(),
        const AsyncSnapshot.withData(ConnectionState.active, 0),
        const AsyncSnapshot.withData(ConnectionState.active, 1),
        const AsyncSnapshot.withData(ConnectionState.done, 1),
      ]);
    },
  );
}
