import 'dart:async';

import 'package:test/test.dart';
import 'package:rxdart/rxdart.dart' as rx;

Stream<int> _getStream() => new Stream<int>.fromIterable(const <int>[1, 2, 3, 4]);

Stream<num> _getErroneousStream() {
  StreamController<num> controller = new StreamController<num>();

  new Timer(const Duration(milliseconds: 100), () => controller.add(1));
  new Timer(const Duration(milliseconds: 200), () => controller.add(2));
  new Timer(const Duration(milliseconds: 300), () => controller.add(3));
  new Timer(const Duration(milliseconds: 400), () {
    controller.add(100 / 0); // throw!!!
    controller.close();
  });

  return controller.stream;
}

void main() {
  test('rx.Observable.startWithMany', () async {
    const List<int> expectedOutput = const <int>[5, 6, 1, 2, 3, 4];
    int count = 0;

    rx.observable(_getStream())
        .startWithMany(const <int>[5, 6])
        .listen(expectAsync1((int result) {
      expect(expectedOutput[count++], result);
    }, count: expectedOutput.length));
  });

  test('rx.Observable.startWithMany.asBroadcastStream', () async {
    Stream<int> observable = rx.observable(_getStream().asBroadcastStream())
        .startWithMany(const <int>[5, 6]);

    // listen twice on same stream
    observable.listen((_) {});
    observable.listen((_) {});
    // code should reach here
    expect(true, true);
  });

  test('rx.Observable.startWithMany.error.shouldThrow', () async {
    Stream<num> observableWithError = rx.observable(_getErroneousStream())
        .startWithMany(const <int>[5, 6]);

    observableWithError.listen(null, onError: (dynamic e, dynamic s) {
      expect(true, true);
    });
  });
}