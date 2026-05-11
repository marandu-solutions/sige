import 'dart:convert';
import 'package:http/http.dart' as http;
import 'event_bus.dart';

/// Observes all events on the EventBus and forwards specific ones to n8n via webhook
class GlobalEventObserver {
  final String webhookUrl;
  
  GlobalEventObserver({required this.webhookUrl});

  /// Starts listening to the EventBus
  void start() {
    EventBus().stream.listen(_handleEvent);
  }

  void _handleEvent(SigeEvent event) async {
    // We can filter which events go to n8n, or send all of them.
    // For this example, we send all events. The n8n router can filter them.
    
    try {
      final payload = jsonEncode(event.toMap());
      
      // Fire and forget webhook
      http.post(
        Uri.parse(webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: payload,
      ).catchError((_) {
        // Ignore network errors on fire-and-forget webhooks
      });
      
      print('Webhook sent to n8n for event: ${event.runtimeType}');
    } catch (e) {
      print('Error sending event to n8n: $e');
    }
  }
}
