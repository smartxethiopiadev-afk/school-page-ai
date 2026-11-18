import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:llamadart/llamadart.dart';
import 'package:path_provider/path_provider.dart';
import '../main.dart';
import '../models/ai_config.dart';
import '../widgets/app_drawer.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final LlamaEngine _engine = LlamaEngine(LlamaBackend());
  ModelDownloadCancelToken? _cancelToken;

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  AIModelOption _selectedModel = AppConfigs.models.first;
  String _selectedGrade = 'Grade 10';
  String _selectedSubject = 'General Tutor';

  ChatSession? _session;
  bool _isDownloading = false;
  bool _isLoadingEngine = false;
  bool _isGenerating = false;
  double _downloadProgress = 0.0;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
  }

  Future<String> _getModelLocalPath(AIModelOption model) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/${model.fileName}';
  }

  Future<void> _checkModelStatus() async {
    final path = await _getModelLocalPath(_selectedModel);
    final exists = await File(path).exists();

    if (!mounted) return;
    setState(() {
      _session = null;
      _statusMessage = '';
    });

    if (exists) {
      await _initializeEngine();
    }
  }

  Future<void> _downloadAndLoadModel() async {
    if (_isDownloading || _isLoadingEngine) return;

    _cancelToken = ModelDownloadCancelToken();
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _statusMessage = '${_selectedModel.name} በመውረድ ላይ ነው...';
    });

    try {
      await _engine.setModel(
        LlamaModel(ModelSource.parse(_selectedModel.uri)),
        params: const ModelParams(
          contextSize: 2048,
          gpuLayers: 0,
        ),
        download: ModelLoadOptions(cancelToken: _cancelToken),
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress.fraction;
            });
          }
        },
      );

      _createSession();
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusMessage = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusMessage = 'ማውረድ አልተቻለም። ኢንተርኔትዎን ያረጋግጡ።';
        });
      }
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel();
    setState(() {
      _isDownloading = false;
      _downloadProgress = 0.0;
      _statusMessage = 'ማውረዱ ተቋርጧል።';
    });
  }

  Future<void> _initializeEngine() async {
    setState(() {
      _isLoadingEngine = true;
      _statusMessage = 'School Page AI እየተዘጋጀ ነው...';
    });

    try {
      await _engine.setModel(
        LlamaModel(ModelSource.parse(_selectedModel.uri)),
        params: const ModelParams(
          contextSize: 2048,
          gpuLayers: 0,
        ),
      );
      _createSession();
      if (mounted) {
        setState(() => _statusMessage = '');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'ሞዴሉን መክፈት አልተቻለም: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingEngine = false);
      }
    }
  }

  void _createSession() {
    _session = ChatSession(
      _engine,
      systemPrompt: AppConfigs.getSystemPrompt(_selectedGrade, _selectedSubject),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? quickPrompt]) async {
    final text = (quickPrompt ?? _inputController.text).trim();
    if (text.isEmpty || _session == null || _isGenerating) return;

    final aiMessage = ChatMessage('', false);
    setState(() {
      if (quickPrompt == null) _inputController.clear();
      _messages.add(ChatMessage(text, true));
      _messages.add(aiMessage);
      _isGenerating = true;
    });
    _scrollToBottom();

    try {
      await for (final chunk in _session!.create(
        [LlamaTextContent(text)],
        params: const GenerationParams(
          maxTokens: 2048,
          temp: 0.35,
        ),
      )) {
        if (chunk.text.isNotEmpty && mounted) {
          setState(() {
            aiMessage.text += chunk.text;
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          aiMessage.text += '\n[ስህተት ተፈጥሯል: $e]';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    _engine.cancelGeneration();
    unawaited(_engine.dispose());
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131314),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131314),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4285F4), Color(0xFF9B72CB)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'School Page AI',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$_selectedGrade • $_selectedSubject',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF8AB4F8),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          const AppUpdateButton(),
          IconButton(
            icon: const Icon(Icons.edit_square, size: 21),
            tooltip: 'አዲስ ውይይት (New Chat)',
            onPressed: () {
              setState(() {
                _messages.clear();
                if (_session != null) _createSession();
              });
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: AppDrawer(
        selectedModel: _selectedModel,
        selectedGrade: _selectedGrade,
        selectedSubject: _selectedSubject,
        onModelChanged: (model) {
          setState(() {
            _selectedModel = model;
            _messages.clear();
          });
          _checkModelStatus();
        },
        onGradeChanged: (grade) {
          setState(() => _selectedGrade = grade);
          if (_session != null) _createSession();
        },
        onSubjectChanged: (subject) {
          setState(() => _selectedSubject = subject);
          if (_session != null) _createSession();
        },
        onNewChat: () {
          setState(() {
            _messages.clear();
            if (_session != null) _createSession();
          });
        },
      ),
      body: Column(
        children: [
          if (_session == null)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1F22),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.downloading_rounded,
                            size: 42,
                            color: Color(0xFF8AB4F8),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _selectedModel.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedModel.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (_isDownloading) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _downloadProgress,
                              minHeight: 8,
                              backgroundColor: Colors.white12,
                              color: const Color(0xFF8AB4F8),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  color: Color(0xFF8AB4F8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _selectedModel.sizeLabel,
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextButton.icon(
                            onPressed: _cancelDownload,
                            icon: const Icon(Icons.close, color: Colors.redAccent),
                            label: const Text(
                              'አቋርጥ (Cancel)',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ] else if (_isLoadingEngine) ...[
                          const CircularProgressIndicator(color: Color(0xFF8AB4F8)),
                          const SizedBox(height: 14),
                          Text(
                            _statusMessage,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ] else ...[
                          ElevatedButton.icon(
                            onPressed: _downloadAndLoadModel,
                            icon: const Icon(Icons.download_rounded, color: Colors.black),
                            label: Text(
                              'Download Model (${_selectedModel.sizeLabel})',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8AB4F8),
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wifi_off_rounded,
                                  size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 6),
                              Text(
                                'አንዴ ከወረደ በኋላ ሙሉ በሙሉ ያለ ኢንተርኔት ይሰራል',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_statusMessage.isNotEmpty &&
                            !_isDownloading &&
                            !_isLoadingEngine)
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Text(
                              _statusMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                      ],
                              else if (_messages.isEmpty)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF4285F4), Color(0xFFD96570)],
                        ).createShader(bounds),
                        child: const Text(
                          'ሰላም ተማሪ!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ዛሬ በ$_selectedGrade $_selectedSubject ምን እንማር?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildSuggestionCard(
                        icon: Icons.quiz_outlined,
                        title: 'የፈተና ጥያቄዎችን አውጣልኝ (Practice Quiz)',
                        subtitle: '5 ምርጫ ጥያቄዎች ከነመልሳቸው እና ማብራሪያቸው',
                        prompt:
                            'Generate 5 multiple-choice exam questions for Ethiopian $_selectedGrade $_selectedSubject with answers and clear step-by-step explanations.',
                      ),
                      const SizedBox(height: 10),
                      _buildSuggestionCard(
                        icon: Icons.functions_rounded,
                        title: 'ዋና ዋና ቀመሮችን እና ሕጎችን አስረዳኝ',
                        subtitle: 'Key formulas, definitions & examples',
                        prompt:
                            'Summarize the most important formulas and concepts in Ethiopian $_selectedGrade $_selectedSubject with simple examples.',
                      ),
                      const SizedBox(height: 10),
                      _buildSuggestionCard(
                        icon: Icons.translate_rounded,
                        title: 'በቀላል እንግሊዝኛ እና በአማርኛ ማጠቃለያ አስረዳኝ',
                        subtitle: 'Simple English explanation + Amharic summary',
                        prompt:
                            'Introduce the core topics of Ethiopian $_selectedGrade $_selectedSubject in simple English and provide a brief Amharic summary.',
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) =>
                    MessageBubble(message: _messages[index]),
              ),
            ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1F22),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        enabled: _session != null && !_isGenerating,
                        style: const TextStyle(color: Colors.white, fontSize: 15.5),
                        maxLines: 5,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: _session == null
                              ? 'መጀመሪያ ሞዴሉን Download ያድርጉ...'
                              : 'ጥያቄህን እዚህ ጻፍ (English / አማርኛ)...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14.5,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: IconButton(
                        onPressed: _isGenerating
                            ? () => _engine.cancelGeneration()
                            : (_session == null ? null : () => _sendMessage()),
                        style: IconButton.styleFrom(
                          backgroundColor: _session == null
                              ? Colors.grey.shade800
                              : (_isGenerating
                                  ? Colors.redAccent
                                  : const Color(0xFF8AB4F8)),
                          padding: const EdgeInsets.all(10),
                        ),
                        icon: Icon(
                          _isGenerating
                              ? Icons.stop_rounded
                              : Icons.arrow_upward_rounded,
                          color: _isGenerating ? Colors.white : Colors.black,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String prompt,
  }) {
    return InkWell(
      onTap: () => _sendMessage(prompt),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1F22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF8AB4F8), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
                  }
                  
  
