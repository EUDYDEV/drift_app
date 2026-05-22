import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class ChatPage extends StatefulWidget {
  final String driverName;
  const ChatPage({super.key, this.driverName = 'Chauffeur'});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();

  // Messages de simulation pré-remplis
  final List<Map<String, dynamic>> _messages = [
    {'isMe': false, 'text': 'Bonjour, je suis en route vers votre position.'},
    {'isMe': true, 'text': 'Super, merci ! Je vous attends au portail.'},
    {
      'isMe': false,
      'text':
          'Parfait, j\'arrive dans 2 minutes. C\'est bien la berline noire ?'
    },
  ];

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _messages.add({'isMe': true, 'text': _controller.text.trim()});
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: _buildAppBar(),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha:0.2),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            color: AppColors.darkText, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.blueViolet,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.driverName,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText,
                ),
              ),
              Text(
                'En ligne',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.green,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone_outlined, color: AppColors.darkText),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Appel en cours...')),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          gradient: isMe ? AppColors.blueViolet : null,
          color: isMe ? null : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha:0.04),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: isMe ? Colors.white : AppColors.darkText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(color: AppColors.white, boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, -5)),
      ]),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(24)),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                      hintText: 'Votre message...',
                      hintStyle: GoogleFonts.montserrat(
                          fontSize: 13, color: AppColors.lightText),
                      border: InputBorder.none),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, gradient: AppColors.blueViolet),
                  child: const Icon(Icons.send, color: Colors.white, size: 20)),
            ),
          ],
        ),
      ),
    );
  }
}
