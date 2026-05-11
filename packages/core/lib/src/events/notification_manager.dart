import 'package:flutter/material.dart';
import 'event_bus.dart';
import 'system_events.dart';

/// A widget that should be placed near the root of the app (e.g., above MaterialApp's builder or in a layout wrapper).
/// It listens to AlertEvents and shows SnackBars globally without needing a BuildContext from the current screen.
class GlobalNotificationOverlay extends StatefulWidget {
  final Widget child;

  const GlobalNotificationOverlay({Key? key, required this.child})
      : super(key: key);

  @override
  _GlobalNotificationOverlayState createState() =>
      _GlobalNotificationOverlayState();
}

class _GlobalNotificationOverlayState extends State<GlobalNotificationOverlay> {
  late final Stream<AlertEvent> _alertStream;

  @override
  void initState() {
    super.initState();
    // Listen to AlertEvents from the EventBus
    _alertStream = EventBus().on<AlertEvent>();
    _alertStream.listen(_showAlert);
  }

  void _showAlert(AlertEvent event) {
    if (!mounted) return;

    Color backgroundColor;
    IconData icon;

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
      default:
        backgroundColor = Colors.blue;
        icon = Icons.info;
        break;
    }

    // Using scaffold messenger if available in the context hierarchy
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(event.message,
                      style: const TextStyle(color: Colors.white))),
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
      print('Could not show SnackBar: ${event.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // We just return the child. The notifications are handled via ScaffoldMessenger
    return widget.child;
  }
}
