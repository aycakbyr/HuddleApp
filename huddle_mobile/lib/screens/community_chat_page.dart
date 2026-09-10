import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/message_service.dart';
import '../services/community_service.dart';
import '../services/auth_service.dart';
import '../utils/snackbar_helper.dart';
import '../utils/chat_date_helper.dart';
import 'community_detail_page.dart';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CommunityChatPage extends StatefulWidget {
    final String communityId;

    const CommunityChatPage({super.key, required this.communityId});

    @override
    State<CommunityChatPage> createState() => _CommunityChatPageState();
}

class _CommunityChatPageState extends State<CommunityChatPage> {
    final _messageService = MessageService();
    final _communityService = CommunityService();
    final _textController = TextEditingController();
    final _scrollController = ScrollController();

    List<Map<String, dynamic>> _messages = [];
    Map<String, dynamic>? _community;
    String? _myUserId;
    bool _isLoading = true;
    bool _isSending = false;
    bool _isAnnouncement = false; // + butonuna basınca true olur mesaj duyuru olarak gönderilir
    final _storage = const FlutterSecureStorage();
    String? _wallpaperPath;
    Set<String> _starredIds = {};
    Timer? _pollTimer;

    @override
    void initState() {
        super.initState();
        _loadData();
        _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _pollMessages());
    }

    @override
    void dispose() {
        _pollTimer?.cancel();
        _textController.dispose();
        _scrollController.dispose();
        super.dispose();
    }

    Future<void> _loadData() async {
        setState(() => _isLoading = true);

        final me = await AuthService().getMe();
        final community = await _communityService.getCommunityById(widget.communityId);
        final messages = await _messageService.getMessages(widget.communityId);
        final wallpaperPath = await _storage.read(key: 'wallpaper_${widget.communityId}');
        final starredRaw = await _storage.read(key: 'starred_${widget.communityId}');
        final starredIds = starredRaw == null ? <String>{} : Set<String>.from(jsonDecode(starredRaw));

        if (!mounted) return;
        setState(() {
            _myUserId = me?['id'];
            _community = community;
            _messages = messages;
            _wallpaperPath = wallpaperPath;
            _starredIds = starredIds;
            _isLoading = false;
        });

        _scrollToBottom();
    }

    // arka planda sessizce yeni mesajları çeker, ekranı yeniden yüklemeden günceller
    Future<void> _pollMessages() async {
        if (!mounted) return;
        try {
            final fresh = await _messageService.getMessages(widget.communityId);
            if (!mounted) return;

            final oldLength = _messages.length;
            final changed = fresh.length != _messages.length || _hasContentChanged(fresh);
            if (!changed) return;

            setState(() => _messages = fresh);

            if (fresh.length > oldLength) {
                _scrollToBottom();
            }
        } catch (e) {
            // sessiz başarısızlık - polling bir sonraki turda tekrar dener
        }
    }

    bool _hasContentChanged(List<Map<String, dynamic>> fresh) {
        for (var i = 0; i < fresh.length && i < _messages.length; i++) {
            if (fresh[i]['isDeleted'] != _messages[i]['isDeleted']) return true;
        }
        return false;
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
        await _storage.write(key: 'starred_${widget.communityId}', value: jsonEncode(_starredIds.toList()));
    }

        void _showMessageOptions(Map<String, dynamic> message) {
        if (message['isDeleted'] == true) return; //silinmiş mesajda menü açılmasın

        final isStarred = _starredIds.contains(message['id']);
        final canDelete = message['senderId'] == _myUserId || _isAdmin;

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
        final result = await _messageService.deleteMessage(widget.communityId, messageId);
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

    void _openCommunityInfo() {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CommunityDetailPage(communityId: widget.communityId),
            ),
        );
    }

    bool get _isAdmin {
        if (_community == null || _myUserId == null) return false;
        final members = List<Map<String, dynamic>>.from(_community!['members']);
        final me = members.where((m) => m['userId'] == _myUserId);
        if (me.isEmpty) return false;
           return me.first['role'] == 'Admin';
    }

    Future<void> _send() async {
        final content = _textController.text.trim();
        if (content.isEmpty) return;

        setState(() => _isSending = true);
        final result = await _messageService.sendMessage(widget.communityId, content, isAnnouncement: _isAnnouncement);
        if (!mounted) return;
        setState(() => _isSending = false);

        if (result['success'] != true) {
            showAppSnackBar(context, result['message'], color: Colors.red);
            return;
        }

        setState(() {
            _messages.add(Map<String, dynamic>.from(result['data']));
            _textController.clear();
            _isAnnouncement = false; //bir sonraki mesaj otomatik normale döner
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
                title: InkWell(
                    onTap: _openCommunityInfo,
                    child: Row(
                        children: [
                            CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF1A237E),
                                backgroundImage: _community?['profilePictureUrl'] != null
                                    ? NetworkImage(_community!['profilePictureUrl'])
                                    : null,
                                child: _community?['profilePictureUrl'] == null
                                    ? const Icon(Icons.groups, color: Colors.white, size: 16)
                                    : null,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                                child: Text(
                                    _community?['name'] ?? 'Sohbet',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Color(0xFF1A237E), fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                            ),
                        ],
                    ),
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
                                        final isAnnouncement = message['isAnnouncement'] == true;
                                        final isStarred = _starredIds.contains(message['id']);
                                        final showDaySeparator = index == 0 || !isSameDay(_messages[index - 1]['sentAt'], message['sentAt']);

                                        final daySeparator = showDaySeparator
                                            ? Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                child: Center(
                                                    child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                        decoration: BoxDecoration(
                                                            color: Colors.black.withOpacity(0.06),
                                                            borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: Text(
                                                            formatDaySeparator(message['sentAt']),
                                                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                                                        ),
                                                    ),
                                                ),
                                            )
                                            : const SizedBox.shrink();

                                        if (isAnnouncement) {
                                            return Column(
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: [
                                                    daySeparator,
                                                    GestureDetector(
                                                        onLongPress: () => _showMessageOptions(message),
                                                        child: Align(
                                                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                                            child: Container(
                                                                margin: const EdgeInsets.symmetric(vertical: 4),
                                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                                                decoration: BoxDecoration(
                                                                    color: Colors.amber.shade100,
                                                                    borderRadius: BorderRadius.circular(12),
                                                                    border: Border.all(color: Colors.amber.shade300),
                                                                ),
                                                                child: Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                        Row(
                                                                            mainAxisSize: MainAxisSize.min,
                                                                            children: [
                                                                                const Icon(Icons.campaign, size: 14, color: Colors.orange),
                                                                                const SizedBox(width: 4),
                                                                                Text(
                                                                                    message['senderDisplayName'],
                                                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
                                                                                ),
                                                                            ],
                                                                        ),
                                                                        const SizedBox(height: 4),
                                                                        message['isDeleted'] == true
                                                                            ? const Text('Bu mesaj silindi', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                                                                            : Text(message['content'], style: const TextStyle(color: Colors.black87)),
                                                                        if (isStarred)
                                                                            const Padding(
                                                                                padding: EdgeInsets.only(top: 4),
                                                                                child: Icon(Icons.star, size: 12, color: Colors.orange),
                                                                            ),
                                                                        Padding(
                                                                            padding: const EdgeInsets.only(top: 4),
                                                                            child: Text(
                                                                                formatMessageTime(message['sentAt']),
                                                                                style: const TextStyle(fontSize: 10, color: Colors.black45),
                                                                            ),
                                                                        ),
                                                                    ],
                                                                ),
                                                            ),
                                                        ),
                                                    ),
                                                ],
                                            );
                                        }

                                        return Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                                daySeparator,
                                                GestureDetector(
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
                                                                    if (!isMe)
                                                                        Text(
                                                                            message['senderDisplayName'],
                                                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                                                                        ),
                                                                    message['isDeleted'] == true
                                                                        ? Text('Bu mesaj silindi', style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontStyle: FontStyle.italic))
                                                                        : Text(message['content'], style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                                                                    if (isStarred)
                                                                        Padding(
                                                                            padding: const EdgeInsets.only(top: 4),
                                                                            child: Icon(Icons.star, size: 12, color: isMe ? Colors.white : Colors.orange),
                                                                        ),
                                                                    Padding(
                                                                        padding: const EdgeInsets.only(top: 4),
                                                                        child: Text(
                                                                            formatMessageTime(message['sentAt']),
                                                                            style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey),
                                                                        ),
                                                                    ),
                                                                ],
                                                            ),
                                                        ),
                                                    ),
                                                ),
                                            ],
                                        );
                                    },
                                ),
                    ),
                    Container(
                        color: const Color(0xFFFAF7F2),
                        child: SafeArea(
                            top: false,
                            child: Column(
                                children: [
                                if (_isAnnouncement)
                                   Container(
                                    width: double.infinity,
                                    color: Colors.amber.shade100,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    child: Row(
                                        children: [
                                            const Icon(Icons.campaign, size: 16, color: Colors.orange),
                                            const SizedBox(width: 6),
                                            const Expanded(
                                                child: Text('Duyuru olarak gönderilecek', style: TextStyle(fontSize: 12, color: Colors.orange)),
                                            ),
                                            GestureDetector(
                                                onTap: () => setState(() => _isAnnouncement = false),
                                                child: const Icon(Icons.close, size: 16, color: Colors.orange),
                                            ),
                                        ],
                                    ),
                                ),
                                Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                        children: [
                                            if (_isAdmin)
                                               IconButton(
                                                onPressed: () => setState(() => _isAnnouncement = !_isAnnouncement),
                                                icon: Icon(
                                                    Icons.campaign,
                                                    color: _isAnnouncement ? Colors.orange : Colors.grey,
                                                ),
                                            ),
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
                            ],
                        ),
                    ),
                    ),
                ],
            ),
            ),
        );
    }
}
