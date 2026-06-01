# flutter_slideable_cell

A Flutter package for list rows with swipe-to-reveal leading and trailing actions, similar to iOS mail cells. It supports gesture-driven open/close, programmatic control via `ValueKey`, full-width expansion, and customizable action layouts.

> **Naming:** the pub package is `flutter_slideable_cell` (import path), while public types use **Slideable** (可滑动), e.g. `SlideableCellView`.

## Features

- **Leading & trailing actions** — swipe horizontally to reveal action buttons on either side.
- **Programmatic control** — `SlideableCellController` opens, closes, and queries cells by unique `ValueKey`.
- **Full expand** — optional full-width expansion with configurable settle behavior (`expand`, `close`, or `open`).
- **Layout modes** — `adjustEdge` (edge-aligned) or `everyItem` (evenly split visible width).
- **Built-in action widget** — `SlideableActionItem` for icon/text combinations and custom children.
- **Interaction tuning** — `openFactor`, `closeFactor`, fling velocity, curves, and durations.
- **Auto-close others** — optionally close other opened cells when one opens.

## Getting started

Add the dependency to `pubspec.yaml`:

```yaml
dependencies:
  flutter_slideable_cell: ^1.0.0
```

Import the library:

```dart
import 'package:flutter_slideable_cell/flutter_slideable_cell.dart';
```

Each `SlideableCellView` must use a **unique** `ValueKey` so the controller can address a single live instance.

## Usage

### Basic list cell

```dart
final SlideableCellController controller = SlideableCellController();

SlideableCellView(
  key: const ValueKey('message_42'),
  controller: controller,
  trailingActions: const [
    SlideableActionItem(
      width: 72,
      slideBackgroundColor: Colors.red,
      icon: Icon(Icons.delete_outline, color: Colors.white),
      text: 'Delete',
    ),
  ],
  child: ListTile(title: Text('Swipe me')),
)
```

### Open and close from code

```dart
await controller.openTrailing(const ValueKey('message_42'));
await controller.closeCell(const ValueKey('message_42'));
await controller.closeAllCells();

final SlideableCellStatus status =
    controller.statusOf(const ValueKey('message_42'));
final bool opened = controller.isOpen(const ValueKey('message_42'));
```

### Leading actions and full expand

```dart
SlideableCellView(
  key: const ValueKey('row_0'),
  controller: controller,
  leadingFullExpandable: true,
  leadingFullExpandBehavior: SlideableExpandBehavior.expand,
  leadingActions: const [
    SlideableActionItem(
      width: 70,
      slideBackgroundColor: Colors.blue,
      text: 'Pin',
    ),
  ],
  trailingActions: const [
    SlideableActionItem(
      width: 76,
      slideBackgroundColor: Colors.orange,
      text: 'Later',
    ),
  ],
  child: const Text('Message content'),
)
```

See the [example](example/lib/main.dart) app for a runnable demo with multiple cells and controller buttons.

## API overview

| Type | Role |
|------|------|
| `SlideableCellView` | Swipeable row widget |
| `SlideableCellController` | Open/close/query by `ValueKey` |
| `SlideableActionItem` | Prebuilt action button layout |
| `SlideableCellExpandMode` | `adjustEdge` or `everyItem` |
| `SlideableExpandBehavior` | Full-expand settle behavior |

## Additional information

- **Repository:** [github.com/flappygod/flutter_slideable_cell](https://github.com/flappygod/flutter_slideable_cell)
- **Issues:** use the GitHub issue tracker on the repository above.

## License

MIT License. See [LICENSE](LICENSE) for details.
