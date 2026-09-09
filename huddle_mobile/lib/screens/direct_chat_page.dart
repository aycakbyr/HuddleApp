import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/direct_message_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../utils/snackbar_helper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DirectChatPage extends StatefulWidget {
    final String otherUserId;

    const DirectChatPage({super.key, required this.otherUserId});

    @override
    State<DirectChatPage> createState() => _DirectChatPageState();
}

class _DirectChatPageState extends State<DirectChatPage> {
    final _messageService = DirectMessageService();
    final _userService = UserService();
    final _textController = TextEditingController();
    final _scrollController = ScrollController();

    List<Map<String, dynamic>> _messages = [];
    Map<String, dynamic>? _otherUser;
    String? _myUserId;
    bool _isLoading = true;
    bool _isSending = false;
    final _storage = const FlutterSecureStorage();
    String? _wallpaperPath;
    Set<String> _starredIds = {};

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
        final otherUser = await _userService.getProfile(widget.otherUserId);
        final messages = await _messageService.getMessages(widget.otherUserId);
        final wallpaperPath = await _storage.read(key: 'wallpaper_dm_${widget.otherUserId}');
        final starredRaw = await _storage.read(key: 'starred_dm_${widget.otherUserId}');
        final starredIds = starredRaw == null ? <String>{} : Set<String>.from(jsonDecode(starredRaw));

        if (!mounted) return;
        setState(() {
            _myUserId = me?['id'];
            _otherUser = otherUser;
            _messages = messages;
            _wallpaperPath = wallpaperPath;
            _starredIds = starredIds;
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

    Future<void> _toggleStar(String messageId) async {
        setState(() {
            if (_starredIds.contains(messageId)) {
                _starredIds.remove(messageId);
            } else {
                _starredIds.add(messageId);
            }
        });
        await _storage.write(key: 'starred_dm_${widget.otherUserId}', value: jsonEncode(_starredIds.toList()));
    }

    void _showMessageOptions(Map<String, dynamic> message) {
        if (message['isDeleted'] == true) return;

        final isStarred = _starredIds.contains(message['id']);
        final canDelete = message['senderId'] == _myUserId; //dm'de yönetici yok, sadece gönderen silebilir

        showModalBottomSheet(
            context: context,
            builder: (context) => SafeArea(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        ListTile(
                            leading: Icon(isStarred ? Icons.star : Icons.star_border, color: Colors.orange),
                            title: Text(isStarred ? 'Yıldızı Kaldır' : 'Yıldızla'),
                            onTap: () {
                                Navigator.pop(context);
                                _toggleStar(message['id']);
                            },
                        ),
                        if (canDelete)
                            ListTile(
                                leading: const Icon(Icons.delete_outline, color: Colors.red),
                                title: const Text('Sil', style: TextStyle(color: Colors.red)),
                                onTap: () {
                                    Navigator.pop(context);
                                    _deleteMessage(message['id']);
                                },
                            ),
                    ],
                ),
            ),
        );
    }

    Future<void> _deleteMessage(String messageId) async {
        final result = await _messageService.deleteMessage(widget.otherUserId, messageId);
        if (!mounted) return;

        if (result['success'] == true) {
            setState(() {
                final index = _messages.indexWhere((m) => m['id'] == messageId);
                if (index != -1) {
                    _messages[index]['isDeleted'] = true;
                    _messages[index]['content'] = '';
                }
            });
        } else {
            showAppSnackBar(context, result['message'], color: Colors.red);
        }
    }

    Future<void> _send() async {
        final content = _textController.text.trim();
        if (content.isEmpty) return;

        setState(() => _isSending = true);
        final result = await _messageService.sendMessage(widget.otherUserId, content);
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
                titleSpacing: 0,
                title: Row(
                    children: [
                        CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF1A237E),
                            backgroundImage: _otherUser?['profilePictureUrl'] != null
                                ? NetworkImage(_otherUser!['profilePictureUrl'])
                                : null,
                            child: _otherUser?['profilePictureUrl'] == null
                                ? const Icon(Icons.person, color: Colors.white, size: 16)
                                : null,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                            child: Text(
                                _otherUser?['displayName'] ?? 'Sohbet',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Color(0xFF1A237E), fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                        ),
                    ],
                ),
                iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
            ),
            body: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: (_wallpaperPath != null && File(_wallpaperPath!).existsSync())
                    ? BoxDecoration(
                        image: DecorationImage(
                            image: FileImage(File(_wallpaperPath!)),
                            fit: BoxFit.cover,
                        ),
                    )
                    : null,
                child: Column(
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
                                        final isStarred = _starredIds.contains(message['id']);

                                        return GestureDetector(
                                            onLongPress: () => _showMessageOptions(message),
                                            child: Align(
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
                                                            message['isDeleted'] == true
                                                                ? Text(
                                                                    'Bu mesaj silindi',
                                                                    style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontStyle: FontStyle.italic),
                                                                )
                                                                : Text(
                                                                    message['content'],
                                                                    style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                                                                ),
                                                            if (isStarred)
                                                                Padding(
                                                                    padding: const EdgeInsets.only(top: 4),
                                                                    child: Icon(Icons.star, size: 12, color: isMe ? Colors.white : Colors.orange),
                                                                ),
                                                        ],
                                                    ),
                                                ),
                                            ),
                                        );
                                    },
                                ),
                    ),
                    Container(
                        color: const Color(0xFFFAF7F2),
                        child: SafeArea(
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
                    ),
                    ],
                ),
            ),
        );
    }
}
