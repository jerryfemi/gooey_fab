/// GooeyFab — a draggable, morphing floating action button for Flutter.
///
/// ## Quick start
///
/// ### Option A — GooeyFabScaffold (easiest)
/// ```dart
/// GooeyFabScaffold(
///   body: MyScreen(),
///   items: [
///     GooeyFabItem(
///       icon: Icons.layers,
///       label: 'Options',
///       onTap: (ctx) => GooeyTransitions.showSheet(
///         ctx,
///         builder: (_) => MyOptionsSheet(),
///       ),
///     ),
///     GooeyFabItem(
///       icon: Icons.info,
///       label: 'Info',
///       onTap: (ctx) => GooeyTransitions.showModal(
///         ctx,
///         builder: (_) => MyInfoDialog(),
///       ),
///     ),
///   ],
/// )
/// ```
///
/// ### Option B — GooeyFab in your own Stack
/// ```dart
/// Stack(
///   children: [
///     MyScreen(),
///     GooeyFab(items: [...]),
///   ],
/// )
/// ```
///
/// ### Option C — single item (FAB directly triggers the action)
/// ```dart
/// GooeyFab(
///   items: [
///     GooeyFabItem(
///       icon: Icons.add,
///       label: 'New',
///       onTap: (ctx) => GooeyTransitions.showScreen(
///         ctx,
///         builder: (_) => NewItemScreen(),
///       ),
///     ),
///   ],
/// )
/// ```
library gooey_fab;

export 'src/gooey_controller.dart';
export 'src/gooey_fab_item.dart';
export 'src/gooey_fab_scaffold.dart';
export 'src/gooey_fab_widget.dart';
export 'src/gooey_transitions.dart' hide registerFabState;
export 'src/blob_effect.dart';
