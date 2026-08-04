/// TAVO — Personality Engine.
///
/// Holds TAVO's active persona and detects voice-triggered switches via
/// simple trigger-phrase matching (fast, free, no extra AI call).
enum Persona {
  friend,
  comedy,
  serious,
  teacher,
  business,
  psychologist,
  storyTeller,
  travelGuide,
}

class _PersonaInfo {
  const _PersonaInfo({
    required this.label,
    required this.triggers,
    required this.promptFragment,
  });

  final String label;
  final List<String> triggers;
  final String promptFragment;
}

class PersonalityEngine {
  Persona _current = Persona.friend;
  Persona get current => _current;
  String get currentLabel => _personas[_current]!.label;

  static final Map<Persona, _PersonaInfo> _personas = {
    Persona.friend: const _PersonaInfo(
      label: 'صديق',
      triggers: ['ارجع طبيعي', 'خلك عادي', 'ارجعني للوضع العادي', 'كفاية مزح', 'خلك صديقي العادي'],
      promptFragment: 'نبرتك: صديق سعودي هادئ وودود، تسولف بشكل طبيعي.',
    ),
    Persona.comedy: const _PersonaInfo(
      label: 'مضحك',
      triggers: ['خلك مضحك', 'كن كوميدي', 'ضحكني', 'سوي نكت', 'خلنا نضحك', 'كن فكاهي'],
      promptFragment: 'نبرتك الحين: مضحك وخفيف الدم بالكامل، نكت وسخرية لطيفة ومبالغة كوميدية في كل رد.',
    ),
    Persona.serious: const _PersonaInfo(
      label: 'جاد',
      triggers: ['خلك جاد', 'كلمني بجدية', 'بدون مزح', 'كن جاد'],
      promptFragment: 'نبرتك الحين: جاد ومتزن، بلا مزح أو نكت، تحليل عميق ومباشر.',
    ),
    Persona.teacher: const _PersonaInfo(
      label: 'معلم',
      triggers: ['علمني', 'اشرح لي', 'خلك معلم', 'درسني', 'كن معلم'],
      promptFragment: 'نبرتك الحين: معلم صبور وواضح، تبسّط الأفكار خطوة خطوة وتتأكد إنها وضحت.',
    ),
    Persona.business: const _PersonaInfo(
      label: 'أعمال',
      triggers: ['تكلم بجدية أعمال', 'خلك محترف', 'استشارة أعمال', 'كن مستشار أعمال'],
      promptFragment: 'نبرتك الحين: مستشار أعمال محترف وعملي، تركّز على القرارات والنتائج الواقعية.',
    ),
    Persona.psychologist: const _PersonaInfo(
      label: 'مستشار',
      triggers: ['أبي أتكلم عن مشاعري', 'خلك مستشار', 'أبي أستشيرك', 'كن مستشار نفسي'],
      promptFragment: 'نبرتك الحين: مستمع هادئ ومتفهّم، تصغي أكثر مما تتكلم، تعليقاتك داعمة ولطيفة.',
    ),
    Persona.storyTeller: const _PersonaInfo(
      label: 'راوي قصص',
      triggers: ['احكيلي قصة', 'خلك راوي', 'سولف لي قصة', 'كن راوي قصص'],
      promptFragment: 'نبرتك الحين: راوي قصص محترف، تفاصيل حسّية وتشويق حقيقي، كل رد جزء من حكاية متصلة.',
    ),
    Persona.travelGuide: const _PersonaInfo(
      label: 'دليل سياحي',
      triggers: ['احكيلي عن السفر', 'خلك دليل سياحي', 'وش تنصحني أسافر', 'كن دليل سياحي'],
      promptFragment: 'نبرتك الحين: دليل سياحي متحمّس وذو خبرة، تتكلم عن أماكن وثقافات وتجارب سفر حقيقية.',
    ),
  };

  /// Checks [userText] for a persona-switch trigger. Returns the matched
  /// persona (and updates [current]), or null if no match.
  Persona? detectSwitch(String userText) {
    final text = userText.trim();
    for (final entry in _personas.entries) {
      for (final trigger in entry.value.triggers) {
        if (text.contains(trigger)) {
          _current = entry.key;
          return entry.key;
        }
      }
    }
    return null;
  }

  String get activePromptFragment => _personas[_current]!.promptFragment;
}