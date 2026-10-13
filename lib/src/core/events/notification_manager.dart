import 'package:flutter/material.dart';
import 'event_bus.dart';
import 'system_events.dart';

/// A widget placed near the root of the app that listens to AlertEvents and shows SnackBars globally
class GlobalNotificationOverlay extends StatefulWidget {
  final Widget child;

  const GlobalNotificationOverlay({super.key, required this.child});

  @override
  State<GlobalNotificationOverlay> createState() =>
      _GlobalNotificationOverlayState();
}

class _GlobalNotificationOverlayState extends State<GlobalNotificationOverlay> {
  late final Stream<AlertEvent> _alertStream;

  @override
  void initState() {
    super.initState();
    _alertStream = EventBus().on<AlertEvent>();
    _alertStream.listen(_showAlert);
  }

  void _showAlert(AlertEvent event) {
    if (!mounted) return;

    Color backgroundColor = Colors.blue;
    IconData icon = Icons.info;

    switch (event.type) {
      case AlertType.success:
        backgroundColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case AlertType.error:
        backgroundColor = Colors.red;
        icon = Icons.error;
        break;
      case AlertType.warning:
        backgroundColor = Colors.orange;
        icon = Icons.warning;
        break;
      case AlertType.info:
        backgroundColor = Colors.blue;
        icon = Icons.info;
        break;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  event.message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint('Could not show SnackBar: ${event.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
