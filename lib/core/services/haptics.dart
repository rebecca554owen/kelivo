import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as HFP;

/// Centralized gentle haptics using the `haptic_feedback` plugin.
///
/// These helpers intentionally keep calls fire-and-forget (no await) and
/// are safe on platforms without plugin support (errors are swallowed).
class Haptics {
  Haptics._();

  /// Very light tap feedback (e.g., small UI taps or success tick).
  static void light() { _safe(() => HFP.Haptics.vibrate(HFP.HapticsType.light)); }

  /// Medium tap feedback (e.g., opening/closing drawer, toggles).
  static void medium() { _safe(() => HFP.Haptics.vibrate(HFP.HapticsType.medium)); }

  static void soft() { _safe(() => HFP.Haptics.vibrate(HFP.HapticsType.soft)); }

  /// Drawer-specific pulse; tuned to feel present but not harsh.
  static void drawerPulse() { _safe(() => HFP.Haptics.vibrate(HFP.HapticsType.soft)); }

  /// Cancel any ongoing vibration (rarely needed in our use cases).
  static void cancel() { /* no-op */ }

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
