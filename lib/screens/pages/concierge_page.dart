import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConciergePage extends StatefulWidget {
  const ConciergePage({super.key});

  @override
  State<ConciergePage> createState() => _ConciergePageState();
}

class _ConciergePageState extends State<ConciergePage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {'isMe': false, 'text': 'Bonjour M. Dubois. Je suis votre conciergerie privée DriFt. Comment puis-je organiser votre journée ?'},
  ];

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _messages.add({'isMe': true, 'text': _controller.text.trim()}));
    _controller.clear();
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _messages.add({'isMe': false, 'text': 'Très bien, je m\'en occupe immédiatement et vous confirme cela d\'ici quelques minutes.'}));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414), // Thème sombre VIP
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
        title: Row(
          children: [
            const Icon(Icons.workspace_premium, color: Color(0xFFFFD700)),
            const SizedBox(width: 8),
            Text('Conciergerie VIP', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg['text'], msg['isMe']);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFFFD700) : Colors.white.withValues(alpha:0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: isMe ? Colors.black87 : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      color: const Color(0xFF1A1A1A),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(24)),
                child: TextField(controller: _controller, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Votre demande spéciale...', hintStyle: GoogleFonts.montserrat(fontSize: 13, color: Colors.white54), border: InputBorder.none), onSubmitted: (_) => _sendMessage()),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(width: 48, height: 48, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFD700)), child: const Icon(Icons.send, color: Colors.black87, size: 20)),
            ),
          ],
        ),
      ),
    );
  }
}