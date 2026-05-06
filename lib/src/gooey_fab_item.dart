import 'package:flutter/material.dart';

/// A single action item displayed as a gooey blob around the FAB.
///
/// Each item peels off the main FAB as its own liquid blob.
/// When tapped, [onTap] fires — use [GooeyTransitions] helpers
/// inside [onTap] to get the full liquid morph animations, or
/// call any arbitrary code (navigate, copy to clipboard, etc.).
///
/// ```dart
/// GooeyFabItem(
///   icon: Icons.add,
///   label: 'New post',
///   onTap: (context) => GooeyTransitions.showSheet(
///     context,
///     builder: (_) => NewPostSheet(),
///   ),
/// )
/// ```
class GooeyFabItem {
  /// Icon shown inside this blob.
  final IconData icon;

  /// Short label shown as a tooltip / accessibility hint.
  final String label;

  /// Called when this blob is tapped.
  /// Receives [BuildContext] so you can call [GooeyTransitions] helpers
  /// or navigate without needing a global key.
  final void Function(BuildContext context) onTap;

  /// Override the blob color for this specific item.
  /// Defaults to the FAB's [GooeyFab.color].
  final Color? color;

  const GooeyFabItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}
