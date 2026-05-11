import 'dart:async';

/// Base class for all events in the system
abstract class SigeEvent {
  final DateTime timestamp;

  SigeEvent() : timestamp = DateTime.now();
  
  /// Helper to serialize event data if it needs to be sent to external services (like n8n)
  Map<String, dynamic> toMap() => {
    'type': runtimeType.toString(),
    'timestamp': timestamp.toIso8601String(),
  };
}

/// A simple, global Event Bus based on Dart Streams.
/// Modules can fire events and listen to specific event types without coupling.
class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  final StreamController<SigeEvent> _streamController = StreamController.broadcast();

  /// Gets the stream of events. Can be filtered by type using .where() or .on<T>()
  Stream<SigeEvent> get stream => _streamController.stream;

  /// Fires an event to all listeners
  void fire(SigeEvent event) {
    if (!_streamController.isClosed) {
      _streamController.add(event);
    }
  }

  /// Listens for a specific type of event [T]
  Stream<T> on<T extends SigeEvent>() {
    return _streamController.stream.where((event) => event is T).cast<T>();
  }

  /// Disposes the event bus. Typically only called on app shutdown.
  void destroy() {
    _streamController.close();
  }
}

/// Helper function for quick access to fire an event
void fireEvent(SigeEvent event) => EventBus().fire(event);
