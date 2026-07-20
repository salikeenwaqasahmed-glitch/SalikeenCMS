import 'dart:async';

/// Emits latest event after [duration] quiet period.
Stream<T> debounceStream<T>(Stream<T> source, Duration duration) {
  Timer? timer;
  late final StreamController<T> controller;
  StreamSubscription<T>? subscription;

  controller = StreamController<T>(
    onListen: () {
      subscription = source.listen(
        (event) {
          timer?.cancel();
          timer = Timer(duration, () {
            if (!controller.isClosed) controller.add(event);
          });
        },
        onError: controller.addError,
        onDone: () {
          timer?.cancel();
          if (!controller.isClosed) controller.close();
        },
      );
    },
    onCancel: () async {
      timer?.cancel();
      await subscription?.cancel();
    },
  );

  return controller.stream;
}
