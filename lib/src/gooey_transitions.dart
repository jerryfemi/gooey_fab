import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:gooey/gooey.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Internal registry
//
// GooeyFab registers its current screen position here so the transition
// helpers know exactly where to start the morph animation from —
// regardless of where the user has dragged the FAB.
// ─────────────────────────────────────────────────────────────────────────────

Offset _fabScreenPosition = const Offset(24, 24);
double _fabRadius = 28;
Color _fabColor = Colors.cyanAccent;

/// Called by [GooeyFab] every time it rebuilds. Internal use only.
void registerFabState({
  required Offset screenPosition,
  required double radius,
  required Color color,
}) {
  _fabScreenPosition = screenPosition;
  _fabRadius = radius;
  _fabColor = color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

/// All three morph-destination helpers live here.
///
/// Call these inside a [GooeyFabItem.onTap] to get the full liquid morph
/// animation. You can also call them from anywhere in your app — they read
/// the FAB's last known position automatically.
abstract class GooeyTransitions {
  GooeyTransitions._();

  // ── 1. Bottom sheet ────────────────────────────────────────────────────────
  //
  // Blob squashes wide → elongates tall (sweat-drop) → dives into the
  // bottom edge. The sheet rises from that exact point while the blob is
  // still visible, so the two motions overlap seamlessly.

  static Future<T?> showSheet<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    Color? color,
    double heightFactor = 0.50,
    Color backgroundColor = const Color(0xFF181818),
  }) {
    final effectiveColor = color ?? _fabColor;
    return Navigator.of(context).push<T>(
      _GooeySheetRoute<T>(
        builder: builder,
        fabPosition: _fabScreenPosition,
        fabRadius: _fabRadius,
        color: effectiveColor,
        heightFactor: heightFactor,
        backgroundColor: backgroundColor,
      ),
    );
  }

  // ── 2. Modal ───────────────────────────────────────────────────────────────
  //
  // Blob races to screen center, blooms outward, then implodes to zero.
  // Dialog springs open with elastic bounce at the exact moment blob = 0.

  static Future<T?> showModal<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    Color? color,
  }) {
    final effectiveColor = color ?? _fabColor;
    return Navigator.of(context).push<T>(
      _GooeyModalRoute<T>(
        builder: builder,
        fabPosition: _fabScreenPosition,
        fabRadius: _fabRadius,
        color: effectiveColor,
      ),
    );
  }

  // ── 3. Full screen ─────────────────────────────────────────────────────────
  //
  // Blob expands as a circle from its exact screen position, flooding the
  // entire screen like ink. The new route fades in as the circle reaches
  // the screen edges. On pop, the circle contracts back to the FAB position.

  static Future<T?> showScreen<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    Color? color,
  }) {
    final effectiveColor = color ?? _fabColor;
    return Navigator.of(context).push<T>(
      _GooeyScreenRoute<T>(
        builder: builder,
        fabPosition: _fabScreenPosition,
        fabRadius: _fabRadius,
        color: effectiveColor,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROUTE 1 — Gooey Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _GooeySheetRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  final Offset fabPosition;
  final double fabRadius;
  final Color color;
  final double heightFactor;
  final Color backgroundColor;

  _GooeySheetRoute({
    required this.builder,
    required this.fabPosition,
    required this.fabRadius,
    required this.color,
    required this.heightFactor,
    required this.backgroundColor,
  });

  @override
  Color? get barrierColor => Colors.black54;
  @override
  String? get barrierLabel => 'Sheet';
  @override
  bool get opaque => false;
  @override
  bool get maintainState => true;
  @override
  Duration get transitionDuration => const Duration(milliseconds: 700);
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 420);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _GooeySheetTransition(
      animation: animation,
      fabPosition: fabPosition,
      fabRadius: fabRadius,
      color: color,
      heightFactor: heightFactor,
      backgroundColor: backgroundColor,
      child: builder(context),
    );
  }
}

class _GooeySheetTransition extends StatelessWidget {
  final Animation<double> animation;
  final Offset fabPosition;
  final double fabRadius;
  final Color color;
  final double heightFactor;
  final Color backgroundColor;
  final Widget child;

  const _GooeySheetTransition({
    required this.animation,
    required this.fabPosition,
    required this.fabRadius,
    required this.color,
    required this.heightFactor,
    required this.backgroundColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Blob animation: 0 → 0.65
    final blobAnim = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.65, curve: Curves.easeInCubic),
    );

    // Sheet animation: 0.50 → 1.0 (overlaps blob by 15%)
    final sheetAnim = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.50, 1.0, curve: Curves.easeOutQuart),
    );

    // Content fade: 0.72 → 1.0
    final contentAnim = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.72, 1.0, curve: Curves.easeIn),
    );

    return Material(
      child: Stack(
        children: [
          // ── Sweat-drop morph blob ──────────────────────────────────────
          // Starts at FAB position, travels to bottom-center,
          // morphing through 3 shape phases along the way.
          AnimatedBuilder(
            animation: blobAnim,
            builder: (_, _) {
              final t = blobAnim.value;
              if (t == 0) return const SizedBox.shrink();
      
              // Position: FAB screen pos → bottom-center
              final startX = fabPosition.dx;
              final startY = fabPosition.dy;
              final endX = size.width / 2;
              final endY = size.height + fabRadius; // off screen bottom
      
              final cx = lerpDouble(startX, endX, t)!;
              final cy = lerpDouble(startY, endY, t)!;
      
              // 3-phase shape morph
              double sx, sy;
              if (t < 0.30) {
                // Phase 1: squash wide
                final p = t / 0.30;
                sx = lerpDouble(1.0, 1.5, p)!;
                sy = lerpDouble(1.0, 0.60, p)!;
              } else if (t < 0.70) {
                // Phase 2: elongate tall (sweat-drop)
                final p = (t - 0.30) / 0.40;
                sx = lerpDouble(1.5, 0.50, p)!;
                sy = lerpDouble(0.60, 2.80, p)!;
              } else {
                // Phase 3: taper to point as it dives in
                final p = (t - 0.70) / 0.30;
                sx = lerpDouble(0.50, 0.15, p)!;
                sy = lerpDouble(2.80, 1.00, p)!;
              }
      
              final d = fabRadius * 2;
              return Positioned(
                left: cx - fabRadius,
                top: cy - fabRadius,
                child: GooeyZone(
                  color: color,
                  gooiness: 0,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(sx, sy),
                    child: GooeyBlob(
                      shape: const BlobShape.circle(),
                      child: Container(
                        width: d,
                        height: d,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      
          // ── Sheet rising from bottom ───────────────────────────────────
          AnimatedBuilder(
            animation: sheetAnim,
            builder: (_, __) {
              final maxH = size.height * heightFactor;
              final currentH = lerpDouble(0, maxH, sheetAnim.value)!;
              if (currentH <= 0) return const SizedBox.shrink();
      
              return Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: currentH,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    border: Border.all(color: Colors.white10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 32,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: FadeTransition(opacity: contentAnim, child: child),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROUTE 2 — Gooey Modal
// ─────────────────────────────────────────────────────────────────────────────

class _GooeyModalRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  final Offset fabPosition;
  final double fabRadius;
  final Color color;

  _GooeyModalRoute({
    required this.builder,
    required this.fabPosition,
    required this.fabRadius,
    required this.color,
  });

  @override
  Color? get barrierColor => Colors.black54;
  @override
  String? get barrierLabel => 'Modal';
  @override
  bool get opaque => false;
  @override
  bool get maintainState => true;
  @override
  Duration get transitionDuration => const Duration(milliseconds: 680);
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 380);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _GooeyModalTransition(
      animation: animation,
      fabPosition: fabPosition,
      fabRadius: fabRadius,
      color: color,
      child: builder(context),
    );
  }
}

class _GooeyModalTransition extends StatelessWidget {
  final Animation<double> animation;
  final Offset fabPosition;
  final double fabRadius;
  final Color color;
  final Widget child;

  const _GooeyModalTransition({
    required this.animation,
    required this.fabPosition,
    required this.fabRadius,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Blob: travels to center and implodes (0 → 0.60)
    final blobAnim = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.60, curve: Curves.easeInOutSine),
    );

    // Dialog: elastic spring-in (0.58 → 1.0) — starts just before blob = 0
    final dialogAnim = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.58, 1.0, curve: Curves.elasticOut),
    );

    // Dialog fade: quick in (0.58 → 0.72)
    final dialogFade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.58, 0.72, curve: Curves.easeIn),
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        // ── Peel blob ─────────────────────────────────────────────────
        AnimatedBuilder(
          animation: blobAnim,
          builder: (_, __) {
            final t = blobAnim.value;
            if (t == 0) return const SizedBox.shrink();

            // Position: FAB → screen center
            final cx = lerpDouble(fabPosition.dx, centerX, t)!;
            final cy = lerpDouble(fabPosition.dy, centerY, t)!;

            // Scale: grow (0→0.45) then implode (0.45→1.0)
            final scale = t < 0.45
                ? lerpDouble(1.0, 1.8, t / 0.45)!
                : lerpDouble(1.8, 0.0, (t - 0.45) / 0.55)!;

            final d = fabRadius * 2;
            return Positioned(
              left: cx - fabRadius,
              top: cy - fabRadius,
              child: Transform.scale(
                scale: scale,
                child: GooeyZone(
                  color: color,
                  gooiness: 0,
                  child: GooeyBlob(
                    shape: const BlobShape.circle(),
                    child: Container(
                      width: d,
                      height: d,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // ── Dialog springs in ─────────────────────────────────────────
        FadeTransition(
          opacity: dialogFade,
          child: ScaleTransition(scale: dialogAnim, child: child),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROUTE 3 — Gooey Screen (circular ink-flood reveal)
// ─────────────────────────────────────────────────────────────────────────────

class _GooeyScreenRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  final Offset fabPosition;
  final double fabRadius;
  final Color color;

  _GooeyScreenRoute({
    required this.builder,
    required this.fabPosition,
    required this.fabRadius,
    required this.color,
  });

  @override
  Color? get barrierColor => null;
  @override
  String? get barrierLabel => null;
  @override
  bool get opaque => true;
  @override
  bool get maintainState => true;
  @override
  Duration get transitionDuration => const Duration(milliseconds: 620);
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 520);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _GooeyCircularReveal(
      animation: animation,
      fabPosition: fabPosition,
      color: color,
      child: child,
    );
  }
}

/// Clips the incoming route as a growing circle that originates from
/// the FAB's exact screen position — the "ink flood" effect.
class _GooeyCircularReveal extends StatelessWidget {
  final Animation<double> animation;
  final Offset fabPosition;
  final Color color;
  final Widget child;

  const _GooeyCircularReveal({
    required this.animation,
    required this.fabPosition,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Max radius = distance from FAB to the farthest screen corner
    final corners = [
      fabPosition,
      Offset(size.width - fabPosition.dx, fabPosition.dy),
      Offset(fabPosition.dx, size.height - fabPosition.dy),
      Offset(size.width - fabPosition.dx, size.height - fabPosition.dy),
    ];
    final maxRadius = corners
        .map((c) => c.distance)
        .reduce((a, b) => a > b ? a : b);

    // Reveal curve: fast start (ink splashes out), eases at edges
    final revealAnim = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
    );

    // Content fades in after circle covers ~60% of screen
    final contentFade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.55, 1.0, curve: Curves.easeIn),
    );

    return AnimatedBuilder(
      animation: revealAnim,
      builder: (_, __) {
        final radius = maxRadius * revealAnim.value;
        return Stack(
          children: [
            // The ink-flood circle (always visible during transition)
            CustomPaint(
              painter: _CirclePainter(
                origin: fabPosition,
                radius: radius,
                color: color,
              ),
              child: const SizedBox.expand(),
            ),

            // The new screen content fades in inside the circle
            ClipPath(
              clipper: _CircleClipper(origin: fabPosition, radius: radius),
              child: FadeTransition(opacity: contentFade, child: child),
            ),
          ],
        );
      },
    );
  }
}

class _CirclePainter extends CustomPainter {
  final Offset origin;
  final double radius;
  final Color color;

  const _CirclePainter({
    required this.origin,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(origin, radius, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CirclePainter old) =>
      old.radius != radius || old.origin != origin;
}

class _CircleClipper extends CustomClipper<Path> {
  final Offset origin;
  final double radius;

  const _CircleClipper({required this.origin, required this.radius});

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: origin, radius: radius));

  @override
  bool shouldReclip(_CircleClipper old) =>
      old.radius != radius || old.origin != origin;
}
