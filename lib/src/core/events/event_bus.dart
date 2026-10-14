import 'dart:async';

abstract class SigeEvent {
  final DateTime timestamp;
  SigeEvent() : timestamp = DateTime.now();

  Map<String, dynamic> toMap() => {
    'type': runtimeType.toString(),
    'timestamp': timestamp.toIso8601String(),
  };
}

class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  final StreamController<SigeEvent> _controller = StreamController.broadcast();

  Stream<SigeEvent> get stream => _controller.stream;

  void fire(SigeEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  void publish(SigeEvent event) => fire(event);


  Stream<T> on<T extends SigeEvent>() {
    return _controller.stream.where((e) => e is T).cast<T>();
  }

  void destroy() {
    _controller.close();
  }
}

void fireEvent(SigeEvent event) => EventBus().fire(event);
