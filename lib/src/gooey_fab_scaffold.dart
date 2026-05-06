import 'package:flutter/material.dart';

import 'gooey_controller.dart';
import 'gooey_fab_item.dart';
import 'gooey_fab_widget.dart';

/// Convenience wrapper that puts a [GooeyFab] into a [Scaffold].
///
/// Use this when you want a FAB on every screen without managing
/// a [Stack] yourself.
///
/// ```dart
/// GooeyFabScaffold(
///   appBar: AppBar(title: Text('My App')),
///   items: [
///     GooeyFabItem(
///       icon: Icons.layers,
///       label: 'Options',
///       onTap: (ctx) => GooeyTransitions.showSheet(ctx, builder: (_) => MySheet()),
///     ),
///   ],
///   body: MyScreen(),
/// )
/// ```
class GooeyFabScaffold extends StatelessWidget {
  /// Your screen body.
  final Widget body;

  /// Action blobs — same as [GooeyFab.items].
  final List<GooeyFabItem> items;

  /// Optional app bar.
  final PreferredSizeWidget? appBar;

  /// Optional bottom navigation bar.
  final Widget? bottomNavigationBar;

  /// Optional drawer.
  final Widget? drawer;

  /// Forwarded to [GooeyFab].
  final Color fabColor;
  final double fabRadius;
  final double subRadius;
  final double gooiness;
  final Offset initialPosition;
  final GooeyFabController? controller;

  const GooeyFabScaffold({
    super.key,
    required this.body,
    required this.items,
    this.appBar,
    this.bottomNavigationBar,
    this.drawer,
    this.fabColor = Colors.cyanAccent,
    this.fabRadius = 30,
    this.subRadius = 24,
    this.gooiness = 80,
    this.initialPosition = const Offset(24, 32),
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      // No floatingActionButton — our FAB lives in the Stack
      // so it can participate in the GooeyZone shader.
      body: Stack(
        children: [
          body,
          GooeyFab(
            items: items,
            color: fabColor,
            radius: fabRadius,
            subRadius: subRadius,
            gooiness: gooiness,
            initialPosition: initialPosition,
            controller: controller,
          ),
        ],
      ),
    );
  }
}
