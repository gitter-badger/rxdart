import 'dart:async';

import 'package:rxdart/src/observable/stream.dart';

class ZipObservable<T> extends StreamObservable<T> with ControllerMixin<T> {

  StreamController<T> _controller;

  ZipObservable(Iterable<Stream<dynamic>> streams, Function predicate, bool asBroadcastStream) {
    final List<bool> pausedStates = new List<bool>.generate(streams.length, (_) => false, growable: false);
    final List<StreamSubscription<dynamic>> subscriptions = new List<StreamSubscription<dynamic>>(streams.length);

    _controller = new StreamController<T>(sync: true,
      onListen: () {
        final List<dynamic> values = new List<dynamic>(streams.length);
        final List<bool> completedStatus = new List<bool>.generate(streams.length, (_) => false);

        void doUpdate(int index, dynamic value) {
          values[index] = value;
          pausedStates[index] = true;

          // subscriptions[i] might be null if doUpdate triggers instantly (i.e. BehaviourSubject)
          if (subscriptions[index] != null) subscriptions[index].pause();

          if (_areAllPaused(pausedStates)) {
            updateWithValues(predicate, values);

            _resumeAll(subscriptions, pausedStates);
          }
        }

        void markDone(int i) {
          completedStatus[i] = true;

          if (completedStatus.reduce((bool a, bool b) => a && b)) _controller.close();
        }

        for (int i=0, len=streams.length; i<len; i++) {
          subscriptions[i] = streams.elementAt(i).listen((dynamic value) => doUpdate(i, value),
            onError: _controller.addError,
            onDone: () => markDone(i));

          // updating the above subscription if doUpdate triggered too soon
          if (pausedStates[i] && !subscriptions[i].isPaused) subscriptions[i].pause();
        }
      },
      onCancel: () => Future.wait(subscriptions
        .map((StreamSubscription<dynamic> subscription) => subscription.cancel())
        .where((Future<dynamic> cancelFuture) => cancelFuture != null))
    );

    setStream(asBroadcastStream ? _controller.stream.asBroadcastStream() : _controller.stream);
  }

  void updateWithValues(Function predicate, Iterable<dynamic> values) {
    try {
      final int len = values.length;
      T result;

      switch (len) {
        case 1: result = predicate(values.elementAt(0)); break;
        case 2: result = predicate(values.elementAt(0), values.elementAt(1)); break;
        case 3: result = predicate(values.elementAt(0), values.elementAt(1), values.elementAt(2)); break;
        case 4: result = predicate(values.elementAt(0), values.elementAt(1), values.elementAt(2), values.elementAt(3)); break;
        case 5: result = predicate(values.elementAt(0), values.elementAt(1), values.elementAt(2), values.elementAt(3), values.elementAt(4)); break;
        case 6: result = predicate(values.elementAt(0), values.elementAt(1), values.elementAt(2), values.elementAt(3), values.elementAt(4), values.elementAt(5)); break;
        case 7: result = predicate(values.elementAt(0), values.elementAt(1), values.elementAt(2), values.elementAt(3), values.elementAt(4), values.elementAt(5), values.elementAt(6)); break;
        case 8: result = predicate(values.elementAt(0), values.elementAt(1), values.elementAt(2), values.elementAt(3), values.elementAt(4), values.elementAt(5), values.elementAt(6), values.elementAt(7)); break;
        case 9: result = predicate(values.elementAt(0), values.elementAt(1), values.elementAt(2), values.elementAt(3), values.elementAt(4), values.elementAt(5), values.elementAt(6), values.elementAt(7), values.elementAt(8)); break;
      }

      _controller.add(result);
    } catch (e, s) {
      _controller.addError(e, s);
    }
  }

  bool _areAllPaused(List<bool> pausedStates) {
    for (int i=0, len=pausedStates.length; i<len; i++) {
      if (!pausedStates[i]) return false;
    }

    return true;
  }

  void _resumeAll(List<StreamSubscription<dynamic>> subscriptions, List<bool> pausedStates) {
    for (int i=0, len=subscriptions.length; i<len; i++) {
      pausedStates[i] = false;
      subscriptions[i].resume();
    }
  }

}