import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_preferences_controller.dart';
import '../../theme/app_theme.dart';

class SupportChatPage extends StatefulWidget {
  const SupportChatPage({super.key});

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = <_ChatMessage>[];

  @override
  void initState() {
    super.initState();
    final french =
        context.read<AppPreferencesController>().languageCode == 'fr';
    _messages.add(
      _ChatMessage(
        text: french
            ? 'Bonjour ! Comment le support Drift peut-il vous aider aujourd’hui ?'
            : 'Hello! How can Drift support help you today?',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(
        _ChatMessage(text: message, isUser: true),
      );
      _messageController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final french =
        context.watch<AppPreferencesController>().languageCode == 'fr';
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              french ? 'Support Drift' : 'Drift Support',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Row(
              children: [
                const CircleAvatar(
                  radius: 4,
                  backgroundColor: Color(0xFF23B26D),
                ),
                const SizedBox(width: 6),
                Text(
                  french ? 'En ligne' : 'Online',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: const Color(0xFF23B26D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _messageBubble(_messages[index], theme),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: french
                            ? 'Écrivez votre message...'
                            : 'Write your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: french ? 'Envoyer' : 'Send',
                    onPressed: _sendMessage,
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.orange,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageBubble(_ChatMessage message, ThemeData theme) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          color: message.isUser
              ? AppTheme.orange
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(message.isUser ? 18 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 18),
          ),
        ),
        child: Text(
          message.text,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            height: 1.4,
            color: message.isUser ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;
}
