import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gooey/gooey.dart';

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

  /// FAB circle radius. Defaults to 30 (60px diameter).
  final double radius;

  /// Sub-blob radius. Defaults to 24 (48px diameter).
  final double subRadius;

  /// How strongly nearby blobs merge. Higher = longer liquid neck.
  final double gooiness;

  /// Starting distance from the bottom-right corner.
  final Offset initialPosition;

  /// Optional controller for programmatic open/close.
  final GooeyFabController? controller;

  const GooeyFab({
    super.key,
    required this.items,
    this.color = Colors.cyanAccent,
    this.radius = 30,
    this.subRadius = 24,
    this.gooiness = 80,
    this.initialPosition = const Offset(24, 32),
    this.controller,
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
      if (_snapCtrl.isAnimating) setState(() => _pos = _snapAnim.value);
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
    super.dispose();
  }

  void _onControllerChanged() {
    final shouldOpen = widget.controller!.isOpen;
    if (shouldOpen && !_menuOpen) _openMenu();
    if (!shouldOpen && _menuOpen) _closeMenu();
  }

  void _openMenu() {
    setState(() => _menuOpen = true);
    _menuCtrl.forward();
  }

  void _closeMenu() {
    _menuCtrl.reverse().then((_) => setState(() => _menuOpen = false));
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
    _menuOpen ? _closeMenu() : _openMenu();
    widget.controller?.isOpen == true ? null : widget.controller?.toggle();
  }

  void _onItemTap(GooeyFabItem item) {
    HapticFeedback.mediumImpact();
    _closeMenu();
    widget.controller?.close();
    _registerPosition();
    // Small delay so cluster finishes collapsing before route pushes
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) item.onTap(context);
    });
  }

  // Tells gooey_transitions.dart where the FAB currently is on screen
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
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _registerPosition();
    final size = MediaQuery.of(context).size;
    final r = widget.radius;
    final sr = widget.subRadius;
    final color = widget.color;
    final count = widget.items.length;

    // Pre-compute spread directions for up to 5 blobs.
    // Blobs fan out in an arc above/beside the FAB.
    // For 1 item this is never called (direct tap path above).
    final directions = _spreadDirections(count);

    return GooeyZone(
      color: color,
      gooiness: widget.gooiness,
      child: Stack(
        children: [
          SizedBox(width: size.width, height: size.height),

          // ── Sub-blobs ────────────────────────────────────────────────
          ...List.generate(count, (i) {
            final item = widget.items[i];
            final blobColor = item.color ?? color;
            final dir = directions[i];

            return AnimatedBuilder(
              animation: _menuAnim,
              builder: (_, _) {
                final t = _menuAnim.value;
                // At t=0: blob sits exactly on FAB → fully merged (one blob)
                // At t=1: blob is spread + gooey neck fully stretched
                const spread = 92.0;
                final dx = dir.dx * spread * t;
                final dy = dir.dy * spread * t;

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
                              size: sr * 0.75,
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
                          color: Colors.black,
                          size: r * 0.85,
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
}

/// Returns unit direction vectors for N sub-blobs arranged in a
/// natural arc. Blobs always spread upward with slight horizontal spread,
/// mirroring which side of the screen the FAB is on.
List<Offset> _spreadDirections(int count) {
  // Angles in degrees: 90° = straight up, fans left/right from there
  // Designed so blobs never spread off-screen.
  const arcTable = {
    1: [90.0],
    2: [112.0, 68.0],
    3: [135.0, 90.0, 45.0],
    4: [135.0, 105.0, 75.0, 45.0],
    5: [150.0, 120.0, 90.0, 60.0, 30.0],
  };
  final angles = arcTable[count]!;
  return angles.map((deg) {
    final rad = deg * 3.14159265 / 180;
    // dx is negative because Positioned.right means we subtract to go left
    return Offset(-1 * -1 * _cos(rad), _sin(rad));
  }).toList();
}

double _cos(double rad) {
  // Simple cos via sin identity
  return _sin(3.14159265 / 2 - rad);
}

double _sin(double rad) {
  // Taylor series (accurate enough for our angles)
  double x = rad;
  while (x > 3.14159265) {
    x -= 2 * 3.14159265;
  }
  while (x < -3.14159265) {
    x += 2 * 3.14159265;
  }
  return x -
      (x * x * x) / 6 +
      (x * x * x * x * x) / 120 -
      (x * x * x * x * x * x * x) / 5040;
}
