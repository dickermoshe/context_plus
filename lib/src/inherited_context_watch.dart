import 'dart:collection';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

@internal
abstract class InheritedContextWatch<TObservable extends Object,
    TSubscription extends Object> extends InheritedWidget {
  const InheritedContextWatch({
    super.key,
    required super.child,
  });

  @override
  ObservableNotifierInheritedElement<TObservable, TSubscription>
      createElement();

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

@internal
abstract class ObservableNotifierInheritedElement<TObservable extends Object,
    TSubscription extends Object> extends InheritedElement {
  ObservableNotifierInheritedElement(super.widget);

  final _contextSubs =
      HashMap<BuildContext, HashMap<TObservable, TSubscription>>();
  final _contextSubsLastFrame =
      HashMap<BuildContext, HashMap<TObservable, TSubscription>>();
  final _manuallyUnwatchedContexts = HashSet<BuildContext>();

  bool _isFirstFrame = true;

  TSubscription? getSubscription(
    BuildContext context,
    TObservable observable,
  ) =>
      _contextSubs[context]?[observable];

  @protected
  TSubscription watch(
    BuildContext context,
    TObservable observable,
    void Function() callback,
  );

  @protected
  void unwatch(
    BuildContext context,
    TObservable observable,
    TSubscription subscription,
  );

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    SchedulerBinding.instance.addPostFrameCallback(_onPostFrame);
  }

  @override
  void unmount() {
    _clearAllSubscriptions();
    super.unmount();
  }

  @override
  void reassemble() {
    _clearAllSubscriptions();
    super.reassemble();
  }

  void _onPostFrame(_) {
    if (!mounted) return;
    _isFirstFrame = false;
    _manuallyUnwatchedContexts.clear();
    _clearSubscriptionsForUnwatchedObservables();
    _clearSubscriptionsForUnmountedContexts();
    SchedulerBinding.instance.addPostFrameCallback(_onPostFrame);
  }

  // Workaround for https://github.com/flutter/flutter/issues/106549
  void _clearSubscriptionsForUnwatchedObservables() {
    // dispose all subscriptions that are no longer present in the frame
    // subscriptions map, but only for elements that are present within the
    // frame context subscriptions map
    for (final context in _contextSubsLastFrame.keys) {
      final frameObservableSubs = _contextSubsLastFrame[context]!;
      final observableSubs = _contextSubs[context]!;
      for (final observable in observableSubs.keys) {
        if (!frameObservableSubs.containsKey(observable)) {
          final sub = observableSubs[observable]!;
          unwatch(context, observable, sub);
        }
      }
      _contextSubs[context] = frameObservableSubs;
      if (observableSubs.isEmpty) {
        _contextSubs.remove(context);
      }
    }
    _contextSubsLastFrame.clear();
  }

  // Workaround for https://github.com/flutter/flutter/issues/128432
  void _clearSubscriptionsForUnmountedContexts() {
    final unmountedContexts = <BuildContext>[];
    for (final context in _contextSubs.keys) {
      if (!context.mounted) {
        unmountedContexts.add(context);
      }
    }
    for (final context in unmountedContexts) {
      _disposeSubscriptionsFor(context);
    }
  }

  void _disposeSubscriptionsFor(BuildContext context) {
    final observableSubs = _contextSubs[context];
    if (observableSubs == null) {
      return;
    }

    for (final MapEntry(key: observable, value: sub)
        in observableSubs.entries) {
      unwatch(context, observable, sub);
    }
    _contextSubs.remove(context);
  }

  void _clearAllSubscriptions() {
    _contextSubsLastFrame.clear();
    _manuallyUnwatchedContexts.clear();

    for (final MapEntry(key: element, value: observableSubs)
        in _contextSubs.entries) {
      for (final MapEntry(key: observable, value: subscription)
          in observableSubs.entries) {
        unwatch(element, observable, subscription);
      }
    }
    _contextSubs.clear();
  }

  @override
  void updateDependencies(Element dependent, Object? aspect) {
    final phase = SchedulerBinding.instance.schedulerPhase;
    final isBuildPhase = phase == SchedulerPhase.persistentCallbacks ||
        _isFirstFrame && phase == SchedulerPhase.idle;

    if (!isBuildPhase) {
      // Don't update subscriptions outside the build phase
      return;
    }

    if (aspect == null) {
      if (_manuallyUnwatchedContexts.contains(dependent)) {
        return;
      }
      _disposeSubscriptionsFor(dependent);
      _manuallyUnwatchedContexts.add(dependent);
      return;
    }

    final observable = aspect as TObservable;

    final observableSubs = _contextSubs.putIfAbsent(dependent, HashMap.new);
    observableSubs[observable] ??=
        watch(dependent, observable, dependent.markNeedsBuild);

    final frameObservableSubs =
        _contextSubsLastFrame.putIfAbsent(dependent, HashMap.new);
    frameObservableSubs[observable] = observableSubs[observable]!;
  }
}
