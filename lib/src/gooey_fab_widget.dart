import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gooey/gooey.dart';

import 'blob_effect.dart';

import 'gooey_controller.dart';
import 'gooey_fab_item.dart';
import 'gooey_transitions.dart';

/// The draggable, gooey FAB widget.
///
/// Place this anywhere in a [Stack]. It manages its own position,
/// the blob cluster open/close animation, and fires [GooeyTransitions]
/// helpers through each [GooeyFabItem.onTap].
///
/// **Minimal usage**
/// ```dart
/// Stack(
///   children: [
///     MyScreenContent(),
///     GooeyFab(
///       items: [
///         GooeyFabItem(
///           icon: Icons.layers,
///           label: 'Menu',
///           onTap: (ctx) => GooeyTransitions.showSheet(ctx, builder: (_) => MySheet()),
///         ),
///       ],
///     ),
///   ],
/// )
/// ```
class GooeyFab extends StatefulWidget {
  /// The action items. Each becomes a gooey blob that peels off the FAB.
  /// Supports 1–5 items. With 1 item, tapping the FAB directly triggers
  /// that item's [onTap] without showing a cluster.
  final List<GooeyFabItem> items;

  /// The gooey blob color. Defaults to [Colors.cyanAccent].
  final Color color;

  /// The icon color shown on the main FAB button.
  final Color iconColor;

  /// FAB circle radius. Defaults to 28 (56px diameter).
  final double radius;

  /// Sub-blob radius. Defaults to 22 (44px diameter).
  final double subRadius;

  /// How strongly nearby blobs merge. Higher = longer liquid neck.
  final double gooiness;

  /// Starting distance from the bottom-right corner.
  final Offset initialPosition;

  /// Optional controller for programmatic open/close.
  final GooeyFabController? controller;

  /// The blob effect. Defaults to [BlobEffect.arc].
  final BlobEffect blobEffect;

  /// Called when the user finishes dragging and the FAB snaps to an edge.
  /// Use this to persist the position yourself (SharedPreferences, Hive, etc.).
  final void Function(Offset position)? onPositionChanged;

  const GooeyFab({
    super.key,
    required this.items,
    this.color = Colors.cyanAccent,
    this.iconColor = Colors.black,
    this.radius = 28,
    this.subRadius = 22,
    this.gooiness = 80,
    this.initialPosition = const Offset(24, 32),
    this.controller,
    this.blobEffect = BlobEffect.arc,
    this.onPositionChanged,
  }) : assert(
         items.length >= 1 && items.length <= 5,
         'GooeyFab supports 1–5 items',
       );

  @override
  State<GooeyFab> createState() => _GooeyFabState();
}

class _GooeyFabState extends State<GooeyFab> with TickerProviderStateMixin {
  late Offset _pos;
  bool _menuOpen = false;

  // Cluster open/close
  late final AnimationController _menuCtrl;
  late final Animation<double> _menuAnim;

  // Edge-snap
  late final AnimationController _snapCtrl;
  late Animation<Offset> _snapAnim;
  bool _ignoreControllerChange = false;

  // ── Morph blobs (rendered inside this GooeyZone for shared shader) ──────
  bool _sheetMorphing = false;
  late final AnimationController _morphSheetCtrl;
  late final Animation<double> _morphSheetAnim;

  bool _modalMorphing = false;
  late final AnimationController _morphModalCtrl;
  late final Animation<double> _morphModalAnim;

  @override
  void initState() {
    super.initState();
    _pos = widget.initialPosition;

    _menuCtrl = AnimationController(
      vsync: this,
      // Slower open → gooey neck stays visible longer
      duration: const Duration(milliseconds: 620),
      reverseDuration: const Duration(milliseconds: 380),
    );
    _menuAnim = CurvedAnimation(parent: _menuCtrl, curve: Curves.easeOutCubic);

    _snapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 440),
    );
    _snapCtrl.addListener(() {
      if (_snapCtrl.isAnimating && mounted) {
        setState(() => _pos = _snapAnim.value);
      }
    });
    _snapCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onPositionChanged?.call(_pos);
      }
    });

    // ── Sheet morph blob ──────────────────────────────────────────────────
    // Blob travels from FAB down toward bottom edge, morphing through
    // 3 shape phases (squash → elongate → taper). Because it's inside
    // the same GooeyZone as the FAB, the shader draws a liquid neck.
    _morphSheetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _morphSheetAnim = CurvedAnimation(
      parent: _morphSheetCtrl,
      curve: Curves.easeInCubic,
    );
    _morphSheetCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        if (mounted) setState(() => _sheetMorphing = false);
        _morphSheetCtrl.reset();
      }
    });

    // ── Modal morph blob ─────────────────────────────────────────────────
    // Blob travels from FAB to screen center, blooms, then implodes.
    _morphModalCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 580),
    );
    _morphModalAnim = CurvedAnimation(
      parent: _morphModalCtrl,
      curve: Curves.easeInOutSine,
    );
    _morphModalCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        if (mounted) setState(() => _modalMorphing = false);
        _morphModalCtrl.reset();
      }
    });

    widget.controller?.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(GooeyFab old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    _menuCtrl.dispose();
    _snapCtrl.dispose();
    _morphSheetCtrl.dispose();
    _morphModalCtrl.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted || _ignoreControllerChange) return;
    final shouldOpen = widget.controller!.isOpen;
    if (shouldOpen && !_menuOpen) _openMenu();
    if (!shouldOpen && _menuOpen) _closeMenu();
  }

  void _openMenu() {
    if (!mounted) return;
    setState(() => _menuOpen = true);
    _menuCtrl.forward();
  }

  void _closeMenu() {
    _menuCtrl.reverse().then((_) {
      if (mounted) setState(() => _menuOpen = false);
    });
  }

  // ── Morph triggers (called from gooey_transitions.dart via registry) ───

  void _startSheetMorph() {
    if (_sheetMorphing) return;
    setState(() => _sheetMorphing = true);
    _morphSheetCtrl.forward();
  }

  void _startModalMorph() {
    if (_modalMorphing) return;
    setState(() => _modalMorphing = true);
    _morphModalCtrl.forward();
  }

  // ── Drag ──────────────────────────────────────────────────────────────────

  void _onPanUpdate(DragUpdateDetails d) {
    if (_snapCtrl.isAnimating) _snapCtrl.stop();
    final size = MediaQuery.of(context).size;
    final pad = MediaQuery.of(context).padding;
    final r = widget.radius;
    setState(() {
      _pos = Offset(
        (_pos.dx - d.delta.dx).clamp(8.0, size.width - r * 2 - 8),
        (_pos.dy - d.delta.dy).clamp(
          8.0,
          size.height - r * 2 - 8 - pad.vertical,
        ),
      );
    });
    // Update registry so transitions start from correct position
    _registerPosition();
  }

  void _onPanEnd(DragEndDetails _) {
    HapticFeedback.lightImpact();
    final size = MediaQuery.of(context).size;
    final r = widget.radius;
    final toRight = _pos.dx > size.width / 2 - r;
    final targetX = toRight ? size.width - r * 2 - 20 : 20.0;
    _snapAnim = Tween<Offset>(
      begin: _pos,
      end: Offset(targetX, _pos.dy),
    ).animate(CurvedAnimation(parent: _snapCtrl, curve: Curves.elasticOut));
    _snapCtrl.forward(from: 0);
  }

  // ── FAB tap ───────────────────────────────────────────────────────────────

  void _onFabTap() {
    // Single item: go directly to its action (no cluster needed)
    if (widget.items.length == 1) {
      HapticFeedback.mediumImpact();
      _registerPosition();
      widget.items.first.onTap(context);
      return;
    }
    HapticFeedback.lightImpact();
    final shouldOpen = !_menuOpen;
    shouldOpen ? _openMenu() : _closeMenu();
    _setControllerOpen(shouldOpen);
  }

  void _onItemTap(GooeyFabItem item) {
    HapticFeedback.mediumImpact();
    _closeMenu();
    _setControllerOpen(false);
    _registerPosition();
    // Small delay so cluster finishes collapsing before route pushes
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) item.onTap(context);
    });
  }

  // Tells gooey_transitions.dart where the FAB currently is on screen
  // and registers the morph callbacks so showSheet/showModal can trigger
  // blob animations inside this widget's GooeyZone.
  void _registerPosition() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = MediaQuery.of(context).size;
    // _pos is distance from bottom-right; convert to top-left screen coords
    final screenX = size.width - _pos.dx - widget.radius;
    final screenY = size.height - _pos.dy - widget.radius;
    registerFabState(
      screenPosition: Offset(screenX, screenY),
      radius: widget.radius.toDouble(),
      color: widget.color,
      onSheetMorph: _startSheetMorph,
      onModalMorph: _startModalMorph,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _registerPosition();
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final r = widget.radius;
    final sr = widget.subRadius;
    final color = widget.color;
    final count = widget.items.length;
    final fs = r * 2; // full FAB diameter

    final fabCenter = Offset(
      size.width - _pos.dx - r,
      size.height - _pos.dy - r,
    );
    const maxSpread = _arcSpread;
    final safeMargin = r + sr + maxSpread + 8;
    final region = _resolveRegion(
      center: fabCenter,
      size: size,
      padding: padding,
      safeMargin: safeMargin,
    );

    final spreadScale = _spreadScaleForCount(count);
    final arcDirections = widget.blobEffect == BlobEffect.arc
        ? _arcDirections(count, _centerAngleForRegion(region))
        : const <Offset>[];

    final stackUp = _stackOpensUp(region);
    final stackDxDir = _stackDxDirection(region);

    return GooeyZone(
      color: color,
      gooiness: widget.gooiness,
      child: Stack(
        children: [
          SizedBox(width: size.width, height: size.height),

          // ── MORPH BLOB: sheet (sweat-drop) ────────────────────────────
          // Same GooeyZone as FAB → shader draws stretching liquid neck.
          // Starts at FAB, squashes wide then elongates vertically
          // (surface-tension drop), dives toward the bottom edge.
          AnimatedBuilder(
            animation: _morphSheetAnim,
            builder: (_, _) {
              if (!_sheetMorphing) return const SizedBox.shrink();
              final t = _morphSheetAnim.value;

              // Position: FAB → bottom-center
              final cx = lerpDouble(
                  _pos.dx, size.width / 2 - fs / 2, t)!;
              final cy = lerpDouble(_pos.dy, -fs * 0.3, t)!;

              // Shape morph: squash (0→0.35) → elongate (0.35→0.75)
              //              → taper to point (0.75→1.0)
              double sx, sy;
              if (t < 0.35) {
                final p = t / 0.35;
                sx = lerpDouble(1.0, 1.45, p)!;
                sy = lerpDouble(1.0, 0.65, p)!;
              } else if (t < 0.75) {
                final p = (t - 0.35) / 0.40;
                sx = lerpDouble(1.45, 0.55, p)!;
                sy = lerpDouble(0.65, 2.60, p)!;
              } else {
                final p = (t - 0.75) / 0.25;
                sx = lerpDouble(0.55, 0.20, p)!;
                sy = lerpDouble(2.60, 0.80, p)!;
              }

              return Positioned(
                right: cx,
                bottom: cy,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..scale(sx, sy),
                  child: GooeyBlob(
                    shape: const BlobShape.circle(),
                    child: Container(
                      width: fs,
                      height: fs,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // ── MORPH BLOB: modal (peel to center) ────────────────────────
          // Same GooeyZone as FAB → gooey neck as it peels away.
          // Races to screen center, blooms outward, then implodes to zero.
          AnimatedBuilder(
            animation: _morphModalAnim,
            builder: (_, _) {
              if (!_modalMorphing) return const SizedBox.shrink();
              final t = _morphModalAnim.value;

              final cx = lerpDouble(
                  _pos.dx, size.width / 2 - fs / 2, t)!;
              final cy = lerpDouble(
                  _pos.dy, size.height / 2 - fs / 2, t)!;

              // Scale: grow (0→0.45) then implode (0.45→1.0)
              final scale = t < 0.45
                  ? lerpDouble(1.0, 1.8, t / 0.45)!
                  : lerpDouble(1.8, 0.0, (t - 0.45) / 0.55)!;

              return Positioned(
                right: cx,
                bottom: cy,
                child: Transform.scale(
                  scale: scale,
                  child: GooeyBlob(
                    shape: const BlobShape.circle(),
                    child: Container(
                      width: fs,
                      height: fs,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Sub-blobs ────────────────────────────────────────────────
          ...List.generate(count, (i) {
            final item = widget.items[i];
            final blobColor = item.color ?? color;
            return AnimatedBuilder(
              animation: _menuAnim,
              builder: (_, _) {
                final t = _menuAnim.value;
                // When menu is closed, remove sub-blobs entirely so only
                // the main FAB renders in the GooeyZone → clean, normal size.
                // Without this, overlapping blobs make the FAB look inflated.
                if (t == 0 && !_menuOpen) return const SizedBox.shrink();
                double dx = 0;
                double dy = 0;

                switch (widget.blobEffect) {
                  case BlobEffect.arc:
                    final dir = arcDirections[i];
                    final spread = _arcSpread * spreadScale;
                    dx = dir.dx * spread * t;
                    dy = dir.dy * spread * t;
                    break;
                  case BlobEffect.stack:
                    dx = _stackDxBias * stackDxDir * t;
                    final step = _stackSpread * spreadScale;
                    final offsetFactor = 1 + (i * 0.85);
                    dy = step * offsetFactor * t * (stackUp ? 1 : -1);
                    break;
                }

                return Positioned(
                  right: _pos.dx - dx,
                  bottom: _pos.dy + dy,
                  child: Tooltip(
                    message: item.label,
                    child: GestureDetector(
                      onTap: () => _onItemTap(item),
                      child: GooeyBlob(
                        shape: const BlobShape.circle(),
                        child: Container(
                          width: sr * 2,
                          height: sr * 2,
                          decoration: BoxDecoration(
                            color: blobColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              item.icon,
                              color: Colors.black.withValues(alpha: 0.8),
                              size: sr * 0.7,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // ── Main FAB ─────────────────────────────────────────────────
          Positioned(
            right: _pos.dx,
            bottom: _pos.dy,
            child: GestureDetector(
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onTap: _onFabTap,
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: GooeyBlob(
                  shape: const BlobShape.circle(),
                  child: Container(
                    width: r * 2,
                    height: r * 2,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 300),
                        turns: _menuOpen ? 0.125 : 0,
                        child: Icon(
                          // Single item: show its icon directly on FAB
                          count == 1 ? widget.items.first.icon : Icons.add,
                          color: widget.iconColor,
                          size: r * 0.82,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setControllerOpen(bool isOpen) {
    final controller = widget.controller;
    if (controller == null) return;
    _ignoreControllerChange = true;
    if (isOpen) {
      controller.open();
    } else {
      controller.close();
    }
    _ignoreControllerChange = false;
  }
}

const double _arcSpread = 92.0;
const double _stackSpread = 80.0;
const double _stackDxBias = 0.0;

enum _FabRegion {
  center,
  left,
  right,
  top,
  bottom,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

_FabRegion _resolveRegion({
  required Offset center,
  required Size size,
  required EdgeInsets padding,
  required double safeMargin,
}) {
  final leftLimit = safeMargin + padding.left;
  final rightLimit = size.width - safeMargin - padding.right;
  final topLimit = safeMargin + padding.top;
  final bottomLimit = size.height - safeMargin - padding.bottom;

  final nearLeft = center.dx < leftLimit;
  final nearRight = center.dx > rightLimit;
  final nearTop = center.dy < topLimit;
  final nearBottom = center.dy > bottomLimit;

  if (nearLeft && nearTop) return _FabRegion.topLeft;
  if (nearRight && nearTop) return _FabRegion.topRight;
  if (nearLeft && nearBottom) return _FabRegion.bottomLeft;
  if (nearRight && nearBottom) return _FabRegion.bottomRight;
  if (nearLeft) return _FabRegion.left;
  if (nearRight) return _FabRegion.right;
  if (nearTop) return _FabRegion.top;
  if (nearBottom) return _FabRegion.bottom;
  return _FabRegion.center;
}

double _centerAngleForRegion(_FabRegion region) {
  switch (region) {
    case _FabRegion.left:
      return 0.0; // fan right
    case _FabRegion.right:
      return 180.0; // fan left
    case _FabRegion.top:
      return 270.0; // fan down
    case _FabRegion.bottom:
      return 90.0; // fan up
    case _FabRegion.topLeft:
      return 315.0; // down-right
    case _FabRegion.topRight:
      return 225.0; // down-left
    case _FabRegion.bottomLeft:
      return 45.0; // up-right
    case _FabRegion.bottomRight:
      return 135.0; // up-left
    case _FabRegion.center:
      return 90.0; // up
  }
}

List<double> _fanOffsetsForCount(int count) {
  switch (count) {
    case 1:
      return const [0.0];
    case 2:
      return const [-25.0, 25.0];
    case 3:
      return const [-45.0, 0.0, 45.0];
    case 4:
      return const [-60.0, -20.0, 20.0, 60.0];
    case 5:
      return const [-80.0, -40.0, 0.0, 40.0, 80.0];
  }
  return const [0.0];
}

double _spreadScaleForCount(int count) {
  switch (count) {
    case 1:
    case 2:
      return 1.0;
    case 3:
      return 0.95;
    case 4:
      return 0.90;
    case 5:
      return 0.85;
  }
  return 1.0;
}

List<Offset> _arcDirections(int count, double centerAngleDeg) {
  final offsets = _fanOffsetsForCount(count);
  return offsets.map((offsetDeg) {
    final deg = centerAngleDeg + offsetDeg;
    final rad = deg * math.pi / 180.0;
    return Offset(math.cos(rad), math.sin(rad));
  }).toList();
}

bool _stackOpensUp(_FabRegion region) {
  switch (region) {
    case _FabRegion.top:
    case _FabRegion.topLeft:
    case _FabRegion.topRight:
      return false;
    default:
      return true;
  }
}

double _stackDxDirection(_FabRegion region) {
  switch (region) {
    case _FabRegion.left:
    case _FabRegion.topLeft:
    case _FabRegion.bottomLeft:
      return 1.0;
    case _FabRegion.right:
    case _FabRegion.topRight:
    case _FabRegion.bottomRight:
      return -1.0;
    default:
      return 0.0;
  }
}
