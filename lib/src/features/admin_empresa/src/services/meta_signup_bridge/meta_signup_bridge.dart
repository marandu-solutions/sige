/// Multiplatform Conditional Bridge for Meta WhatsApp Embedded Signup.
/// Automatically resolves between Web (dart:js_interop) and IO (Mobile/Desktop).
library;

export 'meta_signup_models.dart';
export 'meta_signup_bridge_stub.dart'
    if (dart.library.js_interop) 'meta_signup_bridge_web.dart'
    if (dart.library.io) 'meta_signup_bridge_io.dart';
