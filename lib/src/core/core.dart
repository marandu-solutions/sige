library sige_core;

// Theme & Design Tokens
export 'theme/sige_colors.dart';
export 'theme/sige_typography.dart';
export 'theme/sige_theme.dart';

// Atomic Widgets
export 'widgets/sige_button.dart';
export 'widgets/sige_card.dart';
export 'widgets/sige_text_field.dart';
export 'widgets/sige_badge.dart';
export 'widgets/sige_dialog.dart';

// Shared Models
export 'models/tenant_model.dart';
export 'models/funcionario_model.dart';
export 'models/user_model.dart';
export 'models/lead_model.dart';

// Contracts & IoC
export 'contracts/service_registry.dart';
export 'contracts/i_lead_lookup.dart';
export 'contracts/i_stock_service.dart';

// Events
export 'events/event_bus.dart';
export 'events/system_events.dart';
export 'events/global_event_observer.dart';
export 'events/notification_manager.dart';
