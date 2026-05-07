import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Internal registry
//
// GooeyFab registers its current screen position AND morph callbacks here
// so the transition helpers know exactly where to start the morph animation
// from — regardless of where the user has dragged the FAB.
// ─────────────────────────────────────────────────────────────────────────────

Offset _fabScreenPosition = const Offset(24, 24);
double _fabRadius = 28;
Color _fabColor = Colors.cyanAccent;

// Morph callbacks — called by showSheet / showModal to trigger the blob
// animation inside GooeyFab's GooeyZone (same shader = gooey neck).
VoidCallback? _triggerSheetMorph;
VoidCallback? _triggerModalMorph;

/// Called by [GooeyFab] every time it rebuilds. Internal use only.
void registerFabState({
  required Offset screenPosition,
  required double radius,
  required Color color,
  VoidCallback? onSheetMorph,
  VoidCallback? onModalMorph,
}) {
  _fabScreenPosition = screenPosition;
  _fabRadius = radius;
  _fabColor = color;
  _triggerSheetMorph = onSheetMorph;
  _triggerModalMorph = onModalMorph;
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
  // The morph blob is rendered inside GooeyFab's GooeyZone (shared shader),
  // so it gets the stretchy gooey neck when peeling away. This route only
  // handles the sheet itself rising from the bottom.

  static Future<T?> showSheet<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    Color? color,
    double heightFactor = 0.50,
    Color backgroundColor = const Color(0xFF181818),
  }) {
    // Trigger morph blob inside GooeyFab's GooeyZone
    _triggerSheetMorph?.call();

    final effectiveColor = color ?? _fabColor;
    return Navigator.of(context).push<T>(
      _GooeySheetRoute<T>(
        builder: builder,
        color: effectiveColor,
        heightFactor: heightFactor,
        backgroundColor: backgroundColor,
      ),
    );
  }

  // ── 2. Modal ───────────────────────────────────────────────────────────────
  //
  // Morph blob (peel to center, bloom, implode) is rendered inside GooeyFab's
  // GooeyZone. This route only shows the dialog springing in with elastic.

  static Future<T?> showModal<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    Color? color,
  }) {
    // Trigger morph blob inside GooeyFab's GooeyZone
    _triggerModalMorph?.call();

    final effectiveColor = color ?? _fabColor;
    return Navigator.of(context).push<T>(
      _GooeyModalRoute<T>(
        builder: builder,
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
// ROUTE 1 — Gooey Bottom Sheet (NO blob — blob is in GooeyFab's GooeyZone)
// ─────────────────────────────────────────────────────────────────────────────

class _GooeySheetRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  final Color color;
  final double heightFactor;
  final Color backgroundColor;

  _GooeySheetRoute({
    required this.builder,
    required this.color,
    required this.heightFactor,
    required this.backgroundColor,
  });

  @override
  Color? get barrierColor => Colors.black54;
  @override
  String? get barrierLabel => 'Sheet';
  @override
  bool get barrierDismissible => true;
  @override
  bool get opaque => false;
  @override
  bool get maintainState => true;
  @override
  Duration get transitionDuration => const Duration(milliseconds: 850);
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
      heightFactor: heightFactor,
      backgroundColor: backgroundColor,
      child: builder(context),
    );
  }
}

class _GooeySheetTransition extends StatelessWidget {
  final Animation<double> animation;
  final double heightFactor;
  final Color backgroundColor;
  final Widget child;

  const _GooeySheetTransition({
    required this.animation,
    required this.heightFactor,
    required this.backgroundColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Sheet slides up — delayed until the morph blob (650ms in GooeyFab)
    // has had time to peel off and travel ~70% of the way down.
    // At 0.45 * 850ms = 383ms, which is ~460ms after tap (80ms delay + 383ms),
    // the blob is at 460/650 = ~71% done. Sheet rises as blob arrives.
    final sheetAnim = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOutQuart),
    );

    // Content fade: visible once sheet is mostly risen
    final contentAnim = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.70, 1.0, curve: Curves.easeIn),
    );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
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
// ROUTE 2 — Gooey Modal (NO blob — blob is in GooeyFab's GooeyZone)
// ─────────────────────────────────────────────────────────────────────────────

class _GooeyModalRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  final Color color;

  _GooeyModalRoute({
    required this.builder,
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
  Duration get transitionDuration => const Duration(milliseconds: 750);
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 350);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _GooeyModalTransition(
      animation: animation,
      child: builder(context),
    );
  }
}

class _GooeyModalTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _GooeyModalTransition({
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Dialog springs in — delayed until the morph blob (580ms in GooeyFab)
    // has traveled to center and imploded. At 0.55 * 750ms = 413ms, which
    // is ~493ms after tap (80ms delay + 413ms). Blob is at 493/580 = ~85%
    // done → nearly imploded. Dialog appears right as blob vanishes.
    final dialogAnim = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.55, 1.0, curve: Curves.elasticOut),
    );

    // Dialog fade: quick in as blob finishes imploding
    final dialogFade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.55, 0.72, curve: Curves.easeIn),
    );

    return Stack(
      alignment: Alignment.center,
      children: [
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
      builder: (_, _) {
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
