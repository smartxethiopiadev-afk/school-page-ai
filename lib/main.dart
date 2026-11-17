import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  // AI መልስ የማስመሰል ወይም የማገናኘት ሎጂክ
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "message": text});
      _isLoading = true;
    });

    _controller.clear();

    try {
      // እዚህ ጋር የ AI ሞዴል (WebLLM ወይም API) ጥያቄ የሚላክበትን ኮድ ያስገቡ
      await Future.delayed(const Duration(seconds: 2)); // የማስመሰያ ጊዜ
      
      setState(() {
        _messages.add({
          "sender": "ai", 
          "message": "ይህ ከኢትዮጵያ 9-12ኛ ክፍል መማሪያ መጽሐፍት የተወሰደ ምላሽ ነው: ለጠየቁት ጥያቄ..."
        });
      });
    } catch (e) {
      // ስህተት ሲፈጠር ለተማሪው በ Error Display (SnackBar) ማሳየት
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ስህተት ተፈጥሯል: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Update መፈተሻ ፈንክሽን
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
          // Update ቁልፍ
          IconButton(
            icon: const Icon(Icons.system_update),
            tooltip: 'Check for Updates',
            onPressed: _checkForUpdate,
          ),
        ],
      ),
      body: Column(
        children: [
          // የመልዕክቶች ማሳያ ዝርዝር
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["sender"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  Container(
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
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          // የጽሁፍ መጻፊያ እና መላኪያ ክፍል
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
