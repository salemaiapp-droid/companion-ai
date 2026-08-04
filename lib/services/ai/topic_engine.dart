import 'dart:math';

/// TAVO — Topic Engine.
///
/// Suggests a topic CATEGORY (not a specific fact) for TAVO to draw from,
/// rotating so two back-to-back turns don't land on the same bucket.
class TopicEngine {
  static const _categories = [
    'تاريخ وحضارات',
    'غموض وأسرار',
    'علوم وتكنولوجيا',
    'سفر وأماكن',
    'حياة يومية وطرائف',
    'أفلام وفن',
    'فلسفة وأفكار',
    'رياضة',
  ];

  final _random = Random();
  String? _lastCategory;

  String nextCategory() {
    String pick;
    do {
      pick = _categories[_random.nextInt(_categories.length)];
    } while (pick == _lastCategory && _categories.length > 1);
    _lastCategory = pick;
    return pick;
  }
}