import 'package:flutter/material.dart';

import 'blob_effect.dart';
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
  final Color fabIconColor;
  final double fabRadius;
  final double subRadius;
  final double gooiness;
  final Offset initialPosition;
  final GooeyFabController? controller;
  final BlobEffect blobEffect;

  /// Called when the user drags the FAB to a new position.
  /// Use this to persist the position yourself (SharedPreferences, Hive, etc.).
  final void Function(Offset position)? onPositionChanged;

  const GooeyFabScaffold({
    super.key,
    required this.body,
    required this.items,
    this.appBar,
    this.bottomNavigationBar,
    this.drawer,
    this.fabColor = Colors.cyanAccent,
    this.fabIconColor = Colors.black,
    this.fabRadius = 28,
    this.subRadius = 22,
    this.gooiness = 80,
    this.initialPosition = const Offset(24, 32),
    this.controller,
    this.blobEffect = BlobEffect.arc,
    this.onPositionChanged,
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
            iconColor: fabIconColor,
            radius: fabRadius,
            subRadius: subRadius,
            gooiness: gooiness,
            initialPosition: initialPosition,
            controller: controller,
            blobEffect: blobEffect,
            onPositionChanged: onPositionChanged,
          ),
        ],
      ),
    );
  }
}
