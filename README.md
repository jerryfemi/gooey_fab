# Gooey FAB 💧

A draggable, morphing floating action button for Flutter that feels alive.

Blobs peel apart from the FAB with a **liquid gooey neck**. Tap a blob to trigger one of three morph transitions — each one feels like the blob *becomes* the UI it opens.

## 📺 Demo

<p align="center">
  <video src="assets/demo1.webm" width="45%" muted autoplay loop playsinline></video>
  <video src="assets/demo2.webm" width="45%" muted autoplay loop playsinline></video>
</p>

---

## ✨ Features

- 💧 **Liquid Metaballs**: High-performance shader-based gooey effects.
- 🖐️ **Magnetic Dragging**: Draggable FAB that snaps to screen edges with elastic physics.
- 🎭 **Morph Transitions**: Three unique transition types that bridge the gap between button and content.
- 🎨 **Fully Customizable**: Control gooiness, radii, colors, and spreading effects.
- 📱 **Cupertino & Material**: Works beautifully with any icon set.

---

## 🎭 Transitions

| Transition | Visual Feel | Best For |
|---|---|---|
| `showSheet` | Blob squashes → elongates (sweat-drop) → dives into bottom edge. | Menus, quick options, filter sheets |
| `showModal` | Blob races to center, blooms, implodes → dialog springs open. | Alerts, confirmations, mini-forms |
| `showScreen` | Blob expands as a circle, flooding the screen with ink. | Detail screens, new routes, onboarding |

---

## 🚀 Installation

### From GitHub (Current)
Add this to your `pubspec.yaml`:

```yaml
dependencies:
  gooey_fab:
    git:
      url: https://github.com/jerryfemi/gooey_fab.git
```



---

## Usage

### 1. GooeyFabScaffold (Easiest)

The quickest way to get started. It wraps a standard `Scaffold` and handles the FAB stacking for you.

```dart
GooeyFabScaffold(
  appBar: AppBar(title: Text('My App')),
  body: MyScreen(),
  items: [
    GooeyFabItem(
      icon: CupertinoIcons.layers_fill,
      label: 'Menu',
      onTap: (ctx) => GooeyTransitions.showSheet(
        ctx,
        builder: (_) => MySheet(),
      ),
    ),
    GooeyFabItem(
      icon: CupertinoIcons.bell_fill,
      label: 'Alert',
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

## 🎨 Customization

| Property | Default | Description |
|---|---|---|
| `gooiness` | `80` | How "sticky" the liquid is. Higher = longer necks. |
| `radius` | `28` | Main FAB radius (56px diameter). |
| `subRadius` | `22` | Radius of the menu item blobs. |
| `blobEffect` | `arc` | Choose between `arc` (fan out) or `stack` (vertical list). |

---

## 📝 Performance Tips

The liquid effect uses a **GPU shader** via the `gooey` package.
- Avoid nesting multiple `GooeyZone` widgets.
- Keep the number of sub-blobs to 5 or fewer for the best "stretchy" feel.


