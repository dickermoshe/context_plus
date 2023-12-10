enum ObservableType {
  future,
  synchronousFuture,
  stream,
  valueStream,
  listenable,
  valueListenable,
  signal;

  String get displayName => switch (this) {
        ObservableType.future => 'Future',
        ObservableType.synchronousFuture => 'SynchronousFuture',
        ObservableType.stream => 'Stream',
        ObservableType.valueStream => 'ValueStream',
        ObservableType.listenable => 'Listenable',
        ObservableType.valueListenable => 'ValueListenable',
        ObservableType.signal => 'Signal',
      };

  List<ListenerType> get listenerTypes {
    return switch (this) {
      ObservableType.future => const [
          ListenerType.contextWatch,
          ListenerType.futureBuilder,
        ],
      ObservableType.synchronousFuture => const [
          ListenerType.contextWatch,
          ListenerType.futureBuilder,
        ],
      ObservableType.stream => const [
          ListenerType.contextWatch,
          ListenerType.streamBuilder,
        ],
      ObservableType.valueStream => const [
          ListenerType.contextWatch,
          ListenerType.streamBuilder,
        ],
      ObservableType.listenable => const [
          ListenerType.contextWatch,
          ListenerType.listenableBuilder,
        ],
      ObservableType.valueListenable => const [
          ListenerType.contextWatch,
          ListenerType.valueListenableBuilder,
        ],
      ObservableType.signal => const [
          ListenerType.contextWatch,
          ListenerType.signalsWatch,
          ListenerType.signalsWatchExt,
        ],
    };
  }
}

enum ListenerType {
  contextWatch,
  futureBuilder,
  streamBuilder,
  listenableBuilder,
  valueListenableBuilder,
  signalsWatch,
  signalsWatchExt;

  String displayName(ObservableType observableType) {
    return switch (this) {
      ListenerType.contextWatch => switch (observableType) {
          ObservableType.future => 'Future.watch(context)',
          ObservableType.synchronousFuture =>
            'SynchronousFuture.watch(context)',
          ObservableType.stream => 'Stream.watch(context)',
          ObservableType.valueStream => 'ValueStream.watch(context)',
          ObservableType.listenable => 'Listenable.watch(context)',
          ObservableType.valueListenable => 'ValueListenable.watch(context)',
          ObservableType.signal => 'Signal.watch(context)',
        },
      ListenerType.futureBuilder => 'FutureBuilder',
      ListenerType.streamBuilder => 'StreamBuilder',
      ListenerType.listenableBuilder => 'ListenableBuilder',
      ListenerType.valueListenableBuilder => 'ValueListenableBuilder',
      ListenerType.signalsWatch => 'Watch',
      ListenerType.signalsWatchExt => 'Signal.watch(context) (from signals)',
    };
  }
}
