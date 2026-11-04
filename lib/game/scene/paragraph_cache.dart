import 'dart:collection';
import 'dart:ui' as ui;

/// Small LRU of laid-out paragraphs for text drawn every frame (stack counts,
/// markers). Paragraphs hold native memory the Dart GC barely sees, so
/// building one per frame made memory climb over a session; evicted entries
/// are disposed explicitly.
class ParagraphCache {
  ParagraphCache({this.capacity = 48});

  final int capacity;
  final LinkedHashMap<String, ui.Paragraph> _items = LinkedHashMap();

  int get length => _items.length;

  ui.Paragraph get(String key, ui.Paragraph Function() build) {
    final hit = _items.remove(key);
    if (hit != null) {
      _items[key] = hit;
      return hit;
    }
    final p = build();
    _items[key] = p;
    if (_items.length > capacity) {
      _items.remove(_items.keys.first)!.dispose();
    }
    return p;
  }

  void clear() {
    for (final p in _items.values) {
      p.dispose();
    }
    _items.clear();
  }
}
