import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showTopToast(String message,
    {Color? background, Color? foreground, Duration? duration}) {
  final ctx = Get.overlayContext ?? Get.context;
  if (ctx == null) {
    return;
  }
  final colorScheme = Theme.of(ctx).colorScheme;
  final bg = background ?? colorScheme.surface.withValues(alpha: 0.95);
  final fg = foreground ?? colorScheme.onSurface;
  final d = duration ?? const Duration(seconds: 3);
  final overlay = Overlay.maybeOf(ctx);
  if (overlay == null) {
    return;
  }
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      top: 40,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            message,
            style: TextStyle(color: fg, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Future.delayed(d, entry.remove);
}
