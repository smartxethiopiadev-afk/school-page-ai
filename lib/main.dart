import 'package:flutter/material.dart';

void main() {
  runApp(const EthioEduAiApp());
}

class EthioEduAiApp extends StatelessWidget {
  const EthioEduAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ethio Edu AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List> _messages = [];
  bool _isLoading = false;
  bool _isModelDownloaded = false;
  double _downloadProgress = 0.0;

  void _downloadAiModel() async {
    setState(() {
      _isLoading = true;
    });

    for (int i = 1; i <= 5; i++) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _downloadProgress = i / 5;
      });
    }

    setState(() {
      _isLoading = false;
      _isModelDownloaded = true;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('የ Gemma AI ሞዴል በተሳካ ሁኔታ ወርዷል!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (!_isModelDownloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('እባክዎ መጀመሪያ የ AI ሞዴሉን ያውርዱ!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _messages.add({"sender": "user", "message": text});
      _isLoading = true;
    });

    _controller.clear();

    try {
      await Future.delayed(const Duration(seconds: 2)); 
      
      setState(() {
        _messages.add({
          "sender": "ai", 
          "message": "ይህ ከኢትዮጵያ 9-12ኛ ክፍል መማሪያ መጽሐፍት የተሰጠ ከመስመር ውጭ ምላሽ ነው..."
        });
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ስህተት ተፈጥሯል: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkForUpdate() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ማሻሻያ (Update)'),
        content: const Text('አፕሊኬሽኑ ወቅታዊና ትክክለኛ ስሪት ላይ ይገኛል!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('እሺ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ethio Edu AI - 9-12ኛ ክፍል'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.system_update),
            tooltip: 'Check for Updates',
            onPressed: _checkForUpdate,
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isModelDownloaded)
            Container(
              color: Colors.amber[100],
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Text(
                    'የ AI ሞዴል በስልክዎ ላይ አልተገኘም። እባክዎ ከመስመር ውጭ ለመጠቀም አንዴ ያውርዱት።',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_isLoading)
                    LinearProgressIndicator(value: _downloadProgress)
                  else
                    ElevatedButton.icon(
                      onPressed: _downloadAiModel,
                      icon: const Icon(Icons.download),
                      label: const Text('የ AI ሞዴል አውርድ'),
                    ),
                ],
              ),
            ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["sender"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      msg["message"] ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'ጥያቄዎን እዚህ ይጻፉ...',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
