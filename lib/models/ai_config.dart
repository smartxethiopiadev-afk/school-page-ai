class AIModelOption {
  final String id;
  final String name;
  final String subtitle;
  final String sizeLabel;
  final String uri;
  final String fileName;

  const AIModelOption({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.sizeLabel,
    required this.uri,
    required this.fileName,
  });
}

class AppConfigs {
  static const List<AIModelOption> models = [
    AIModelOption(
      id: 'qwen_math',
      name: 'Math & Science Pro (Qwen 1.5B)',
      subtitle: 'ለሒሳብ፣ ፊዚክስ እና ኬሚስትሪ ስሌቶች ምርጥ',
      sizeLabel: '1.1 GB',
      uri: 'hf://Qwen/Qwen2.5-1.5B-Instruct-GGUF/qwen2.5-1.5b-instruct-q4_k_m.gguf',
      fileName: 'qwen2.5-1.5b-instruct-q4_k_m.gguf',
    ),
    AIModelOption(
      id: 'gemma_amharic',
      name: 'Amharic & Tutor (Gemma 4 E2B)',
      subtitle: 'አማርኛን ለመረዳት እና ለማብራሪያ ትምህርቶች',
      sizeLabel: '1.8 GB',
      uri: 'hf://unsloth/gemma-4-E2B-it-GGUF/gemma-4-E2B-it-Q4_K_M.gguf',
      fileName: 'gemma-4-E2B-it-Q4_K_M.gguf',
    ),
  ];

  static const List<String> grades = [
    'Grade 9',
    'Grade 10',
    'Grade 11',
    'Grade 12',
  ];

  static const List<String> subjects = [
    'General Tutor',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
    'History',
    'Geography',
  ];

  static String getSystemPrompt(String grade, String subject) {
    return '''
You are School Page AI, an expert offline tutor for Ethiopian $grade students specializing in $subject.
- Support both English and Amharic. If the student asks in Amharic, understand it carefully, explain clearly in simple English (matching Ethiopian curriculum terms), and add a helpful Amharic summary.
- Solve Math, Physics, and Chemistry problems step-by-step without skipping steps.
- Never cut off explanations; finish every point completely.
- Keep formatting clean with bullet points and numbered steps.
''';
  }
}
