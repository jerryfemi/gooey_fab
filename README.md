# gooey_fab

A draggable, morphing floating action button for Flutter.

Blobs peel apart from the FAB with a **liquid gooey neck**. Tap a blob to trigger one of three morph transitions — each one feels like the blob *becomes* the UI it opens.

---

## Transitions

| Transition | Feel | Use for |
|---|---|---|
| `showSheet` | Blob squashes → elongates (sweat-drop) → dives into the bottom edge as the sheet rises | Menus, options, quick actions |
| `showModal` | Blob races to center, blooms, implodes → dialog springs open elastically | Confirmations, alerts, mini forms |
| `showScreen` | Blob expands as a circle from its exact position, flooding the screen with color | New routes, detail screens, onboarding |

---

## Installation

```yaml
dependencies:
  gooey_fab: ^0.1.0
```

---

## Usage

### GooeyFabScaffold (easiest)

Wraps a `Scaffold` and places the FAB automatically.

```dart
GooeyFabScaffold(
  appBar: AppBar(title: Text('My App')),
  body: MyScreen(),
  items: [
    GooeyFabItem(
      icon: Icons.layers_rounded,
      label: 'Options',
      onTap: (ctx) => GooeyTransitions.showSheet(
        ctx,
        builder: (_) => MyOptionsSheet(),
      ),
    ),
    GooeyFabItem(
      icon: Icons.info_rounded,
      label: 'About',
      onTap: (ctx) => GooeyTransitions.showModal(
        ctx,
        builder: (_) => MyAboutDialog(),
      ),
    ),
    GooeyFabItem(
      icon: Icons.open_in_full_rounded,
      label: 'Details',
      onTap: (ctx) => GooeyTransitions.showScreen(
        ctx,
        builder: (_) => DetailsScreen(),
      ),
    ),
  ],
)
```

### GooeyFab in your own Stack

If you already manage a `Stack`, drop `GooeyFab` in directly.

```dart
Stack(
  children: [
    MyScreen(),
    GooeyFab(items: [...]),
  ],
)
```

### Single item (no cluster)

When you pass exactly one item, tapping the FAB fires it directly
with no sub-blob cluster — the FAB icon becomes the item's icon.

```dart
GooeyFab(
  items: [
    GooeyFabItem(
      icon: Icons.add,
      label: 'New post',
      onTap: (ctx) => GooeyTransitions.showScreen(
        ctx,
        builder: (_) => NewPostScreen(),
      ),
    ),
  ],
)
```

### Programmatic control

```dart
final _controller = GooeyFabController();

GooeyFab(
  controller: _controller,
  items: [...],
)

// Elsewhere in your code:
_controller.open();
_controller.close();
_controller.toggle();
```

---

## Customisation

```dart
GooeyFab(
  color: Colors.deepPurpleAccent,   // blob color
  radius: 32,                        // FAB radius in px
  subRadius: 26,                     // sub-blob radius
  gooiness: 90,                      // neck strength (0–100)
  initialPosition: Offset(24, 80),   // distance from bottom-right
  items: [
    GooeyFabItem(
      icon: Icons.star,
      label: 'Star',
      color: Colors.amberAccent,     // per-item color override
      onTap: (ctx) { /* anything */ },
    ),
  ],
)
```

### Your content, your widgets

`showSheet`, `showModal`, and `showScreen` accept any widget as content.
The morph animation is owned by `gooey_fab` — your widget just fills the space.

```dart
// showSheet — builder receives BuildContext
GooeyTransitions.showSheet(
  context,
  builder: (ctx) => MyCompletelyCustomSheet(),
  heightFactor: 0.65,            // how tall the sheet is (default 0.50)
  backgroundColor: Colors.white, // sheet background
);

// showModal — any widget, not just AlertDialog
GooeyTransitions.showModal(
  context,
  builder: (ctx) => MyCustomCard(),
);

// showScreen — a full Scaffold, a simple widget, anything
GooeyTransitions.showScreen(
  context,
  builder: (ctx) => MyDetailScreen(),
);
```

---

## How the gooey neck works

All blobs — the main FAB and every sub-blob — share a single `GooeyZone`
from the [gooey](https://pub.dev/packages/gooey) package. At `t=0` every
sub-blob sits exactly on top of the FAB (fully merged, looks like one blob).
As the animation progresses they pull apart, and the `GooeyZone` shader draws
the stretching liquid neck between them automatically.

---

## Requirements

- Flutter ≥ 3.10
- Dart ≥ 3.0
- [gooey](https://pub.dev/packages/gooey) ≥ 0.2.0

---

## License

MIT
