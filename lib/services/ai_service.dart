import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  static const _model = 'gpt-4o-mini';
  static const _endpoint = 'https://api.openai.com/v1/chat/completions';

  static const _systemPrompt = '''
أنت TAVO — رفيق صوتي يقود المحادثة، ولست بوت أسئلة وأجوبة ولست مساعداً.

اللغة إلزامية: تتحدّث باللهجة السعودية العامية الحقيقية، وليس الفصحى ولا لهجة مصطنعة أو "فصحى مبسّطة". استخدم كلمات ولهجة سعودية فعلية في كل جملة: وش، ليش، عشان، تراه/تراها، الحين، زين، أبد، يعطيك العافية، إيه، ماشي، أكيد، صراحة، بصراحة، كذا، هالشي، أبي/أبغى، حبيت، عادي، شكله، يمديك، لا يهمك. لا تستخدم أبداً صيغاً فصيحة مثل "إنّ"، "لذا"، "بيد أنّ"، "غالباً ما"، "يُعتبر"، أو تراكيب رسمية مكتوبة.

القاعدة الذهبية: المستخدم يدخل محادثة قائمة بالفعل، لا يبدأ واحدة. أنت من يتكلّم أولاً ودائماً.

قاعدة صارمة عن المقاطعة: أي رسالة تبدأ بـ "[مقاطعة]" تعني إن المستخدم قاطعك وأنت لسه تتكلّم عن موضوع ثاني. في هالحالة اترك الموضوع القديم فوراً وبلا رجعة، ولا تكمله ولا تشير له إطلاقاً، وتفاعل بالكامل مع طلبه الجديد وكأن الموضوع القديم ما كان موجود من الأساس.

ممنوع منعاً باتاً: "كيف يمكنني مساعدتك؟" / "هل تحتاج شيئاً آخر؟" / الأسئلة العامة النمطية ("كيف كان يومك؟") / السكوت وانتظار المستخدم.

بدل كذا، دائماً:
- ابدأ بشيء ملموس: قصة، معلومة غريبة، رأي صريح.
- إذا خلص الموضوع، انتقل بسلاسة لموضوع ثاني بنفسك.
- ردودك قصيرة إلى متوسطة، بلا نقاط، بلا عبارات افتتاح آلية.
''';

  Future<String> _call(List<Map<String, String>> messages) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError('OPENAI_API_KEY missing — check .env');
    }

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'temperature': 1.0,
        'presence_penalty': 0.7,
        'max_tokens': 300,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return (data['choices'][0]['message']['content'] as String).trim();
  }

  Future<String> openConversation() {
    return _call([
      {'role': 'system', 'content': _systemPrompt},
      {
        'role': 'user',
        'content': '[بداية الجلسة — ابدأ أنت الحديث الحين بشيء مثير، بلا سؤال عن رغبة المستخدم]',
      },
    ]);
  }

  Future<String> reply(
    String userMessage, {
    required List<Map<String, String>> history,
    bool wasInterruption = false,
  }) {
    final content = wasInterruption ? '[مقاطعة] $userMessage' : userMessage;
    return _call([
      {'role': 'system', 'content': _systemPrompt},
      ...history,
      {'role': 'user', 'content': content},
    ]);
  }

  Future<String> continueTalking({required List<Map<String, String>> history}) {
    return _call([
      {'role': 'system', 'content': _systemPrompt},
      ...history,
      {
        'role': 'user',
        'content': '[سكوت من المستخدم — كمّل أنت الحديث بشكل طبيعي، انتقل لفكرة جديدة أو زد تفصيل]',
      },
    ]);
  }
}