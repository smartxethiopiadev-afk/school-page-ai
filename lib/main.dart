import 'dart:async';
import 'package:flutter/material.dart';
import 'package:llamadart/llamadart.dart';

const String modelUri =
    'hf://unsloth/gemma-3-1b-it-GGUF/'
    'gemma-3-1b-it-Q4_K_M.gguf';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EthioEduAI());
}

class EthioEduAI extends StatelessWidget {
  const EthioEduAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ethio Edu AI',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatMessage {
  ChatMessage(this.text, this.isUser);

  String text;
  final bool isUser;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final LlamaEngine _engine = LlamaEngine(LlamaBackend());
  final ModelDownloadCancelToken _cancelToken =
      ModelDownloadCancelToken();

  final TextEditingController _input = TextEditingController();
  final List<ChatMessage> _messages = [];

  ChatSession? _session;

  String _status = 'AI Model በመዘጋጀት ላይ...';
  double? _progress;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadModel());
  }

  Future<void> _loadModel() async {
    setState(() {
      _status = 'Gemma AI Model በማውረድ ላይ...';
    });

    try {
      await _engine.setModel(
        LlamaModel(ModelSource.parse(modelUri)),
        params: const ModelParams(
          contextSize: 2048,
          gpuLayers: 0,
        ),
        download: ModelLoadOptions(
          cancelToken: _cancelToken,
        ),
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _progress = progress.fraction;
            });
          }
        },
      );

      if (!mounted) return;

      _session = ChatSession(
        _engine,
        systemPrompt: '''
You are Ethio Edu AI, an educational tutor
for Ethiopian students in grades 9-12.

Explain concepts clearly and step by step.
Support Amharic and English.
Help students with Mathematics, Physics,
Chemistry, Biology and other school subjects.
Use simple language and educational examples.
If you do not know an answer, say so honestly.
''',
      );

      setState(() {
        _status = 'Ethio Edu AI ዝግጁ ነው!';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _status = 'Model loading failed: $e';
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _input.text.trim();
    final session = _session;

    if (text.isEmpty || session == null || _generating) {
      return;
    }

    final reply = ChatMessage('', false);

    setState(() {
      _input.clear();
      _messages.add(ChatMessage(text, true));
      _messages.add(reply);
      _generating = true;
    });

    try {
      await for (final chunk in session.create(
        <LlamaContentPart>[
          LlamaTextContent(text),
        ],
        params: const GenerationParams(
          maxTokens: 256,
          temp: 0.7,
        ),
      )) {
        if (chunk.text.isNotEmpty && mounted) {
          setState(() {
            reply.text += chunk.text;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          reply.text += '\nError: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _generating = false;
        });
      }
    }
  }

  void _stopGeneration() {
    _engine.cancelGeneration();
  }

  @override
  void dispose() {
    _cancelToken.cancel();
    _engine.cancelGeneration();
    unawaited(_engine.dispose());
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text('Ethio Edu AI - Grade 9-12'),
      ),
      body: Column(
        children: [
          if (_session == null) ...[
            LinearProgressIndicator(value: _progress),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _status,
                textAlign: TextAlign.center,
              ),
            ),
          ],
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];

                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.all(14),
                    constraints: const BoxConstraints(
                      maxWidth: 320,
                    ),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? Colors.blue.shade100
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      message.text.isEmpty ? '...' : message.text,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      enabled: _session != null && !_generating,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'ጥያቄህን እዚህ ጻፍ...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _generating
                        ? _stopGeneration
                        : (_session == null ? null : _sendMessage),
                    icon: Icon(
                      _generating ? Icons.stop : Icons.send,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}