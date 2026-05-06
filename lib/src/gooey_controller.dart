import 'package:flutter/foundation.dart';

/// Optional controller that lets parent code open or close
/// the FAB cluster programmatically — without the user tapping.
///
/// ```dart
/// final _controller = GooeyFabController();
///
/// GooeyFab(
///   controller: _controller,
///   items: [...],
/// )
///
/// // Elsewhere:
/// _controller.open();
/// _controller.close();
/// _controller.toggle();
/// ```
class GooeyFabController extends ChangeNotifier {
  bool _isOpen = false;

  bool get isOpen => _isOpen;

  /// Opens the blob cluster.
  void open() {
    if (_isOpen) return;
    _isOpen = true;
    notifyListeners();
  }

  /// Closes the blob cluster.
  void close() {
    if (!_isOpen) return;
    _isOpen = false;
    notifyListeners();
  }

  /// Toggles open/closed.
  void toggle() => _isOpen ? close() : open();
}
