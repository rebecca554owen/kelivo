import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

/// Centralized gentle haptics/vibration using the `vibration` plugin.
///
/// These helpers intentionally keep calls fire-and-forget (no await) and
/// are safe on platforms without plugin support (errors are swallowed).
class Haptics {
  Haptics._();

  /// Very light tap feedback (e.g., small UI taps or success tick).
  static void light() {
    _safe(() => Vibration.vibrate(
          // Single crisp-soft pulse
          duration: 12,
          amplitude: 80,
          sharpness: 0.40,
        ));
  }

  /// Medium tap feedback (e.g., opening/closing drawer, toggles).
  static void medium() {
    _safe(() => Vibration.vibrate(
          // Single pulse: a bit longer/stronger but not harsh
          duration: 16,
          amplitude: 110,
          sharpness: 0.36,
        ));
  }

  /// Drawer-specific pulse; tuned to feel present but not harsh.
  static void drawerPulse() {
    _safe(() => Vibration.vibrate(
          // Single pulse for drawer
          duration: 18,
          amplitude: 125,
          sharpness: 0.34,
        ));
  }

  /// Cancel any ongoing vibration (rarely needed in our use cases).
  static void cancel() {
    _safe(() => Vibration.cancel());
  }

  // Fire-and-forget wrapper to avoid exceptions on unsupported platforms.
  static void _safe(Future<void> Function() action) {
    if (kIsWeb) return; // Skip on web targets
    try {
      // Don't await; haptic should not block UI.
      // ignore: discarded_futures
      action();
    } catch (_) {
      // Swallow any MissingPluginException or platform channel errors.
    }
  }
}
