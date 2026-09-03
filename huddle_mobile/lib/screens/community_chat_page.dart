import 'package:flutter/material.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';
import '../utils/snackbar_helper.dart';

class CommunityChatPage extends StatefulWidget {
    final String communityId;

    const CommunityChatPage({super.key, required this.communityId});

    @override
    State<CommunityChatPage> createState() => _CommunityChatPageState();
}

class _CommunityChatPageState extends State<CommunityChatPage> {
    final _messageService = MessageService();
    final _textController = TextEditingController();
    final _scrollController = ScrollController();

    List<Map<String, dynamic>> _messages = [];
    String? _myUserId;
    bool _isLoading = true;
    bool _isSending = false;

    @override
    void initState() {
        super.initState();
        _loadData();
    }

    @override
    void dispose() {
        _textController.dispose();
        _scrollController.dispose();
        super.dispose();
    }

    Future<void> _loadData() async {
        setState(() => _isLoading = true);

        final me = await AuthService().getMe();
        final messages = await _messageService.getMessages(widget.communityId);

        if (!mounted) return;
        setState(() {
            _myUserId = me?['id'];
            _messages = messages;
            _isLoading = false;
        });

        _scrollToBottom();
    }

    void _scrollToBottom() {
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_scrollController.hasClients) return;
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
    }

    Future<void> _send() async {
        final content = _textController.text.trim();
        if (content.isEmpty) return;

        setState(() => _isSending = true);
        final result = await _messageService.sendMessage(widget.communityId, content);
        if (!mounted) return;
        setState(() => _isSending = false);

        if (result['success'] != true) {
            showAppSnackBar(context, result['message'], color: Colors.red);
            return;
        }

        setState(() {
            _messages.add(Map<String, dynamic>.from(result['data']));
            _textController.clear();
        });
        _scrollToBottom();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: const Color(0xFFFAF7F2),
            appBar: AppBar(
                backgroundColor: const Color(0xFFFAF7F2),
                elevation: 0,
                title: const Text('Sohbet', style: TextStyle(color: Color(0xFF1A237E))),
                iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
            ),
            body: Column(
                children: [
                    Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _messages.isEmpty
                                ? const Center(child: Text('Henüz mesaj yok. İlk mesajı sen gönder!'))
                                : ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _messages.length,
                                    itemBuilder: (context, index) {
                                        final message = _messages[index];
                                        final isMe = message['senderId'] == _myUserId;

                                        return Align(
                                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                            child: Container(
                                                margin: const EdgeInsets.symmetric(vertical: 4),
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                                decoration: BoxDecoration(
                                                    color: isMe ? const Color(0xFF1A237E) : Colors.white,
                                                    borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                        if (!isMe)
                                                            Text(
                                                                message['senderDisplayName'],
                                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                                                            ),
                                                        Text(
                                                            message['content'],
                                                            style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                                                        ),
                                                    ],
                                                ),
                                            ),
                                        );
                                    },
                                ),
                    ),
                    SafeArea(
                        top: false,
                        child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                                children: [
                                    Expanded(
                                        child: TextField(
                                            controller: _textController,
                                            decoration: InputDecoration(
                                                hintText: 'Mesaj yaz...',
                                                filled: true,
                                                fillColor: Colors.white,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(24),
                                                    borderSide: BorderSide.none,
                                                ),
                                            ),
                                        ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                        onPressed: _isSending ? null : _send,
                                        icon: const Icon(Icons.send, color: Color(0xFF1A237E)),
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