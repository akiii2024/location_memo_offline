import '../models/memo.dart';

/// オフライン版ではAI機能を提供しないため、呼び出し元と互換性のあるスタブ実装を用意する。
class AIService {
  static bool get isConfigured => false;

  static void printDebugInfo() {}

  static Map<String, dynamic> checkApiKeyStatus() => const {
        'isConfigured': false,
        'isEmpty': true,
        'length': 0,
      };

  static Future<dynamic> analyzeImageBytes(List<int> bytes) async =>
      _unsupported('画像分析');

  static Future<dynamic> analyzeImage(Object file) async =>
      _unsupported('画像分析');

  static Future<String> transcribeAudio(String path) async =>
      _unsupported('音声文字起こし');

  static Future<String> improveMemoContent(String content) async =>
      _unsupported('テキスト改善');

  static Future<String> askQuestion(
    String question,
    List<Memo> memos,
  ) async =>
      _unsupported('質問応答');

  static Future<Map<String, dynamic>> recognizeMultipleRecordsFromImage(
          List<int> bytes) async =>
      _unsupported('複数地点記録読み取り');

  static Future<Map<String, dynamic>> testApiConnection() async =>
      const {'success': false, 'message': 'AI機能は無効です'};

  static T _unsupported<T>(String feature) {
    throw UnsupportedError('オフライン版では$feature機能を利用できません');
  }
}
