import 'package:flutter/material.dart';
import '../services/message_service.dart';
import '../services/community_service.dart';
import '../services/auth_service.dart';
import '../utils/snackbar_helper.dart';
import 'community_detail_page.dart';

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
        final community = await _communityService.getCommunityById(widget.communityId);
        final messages = await _messageService.getMessages(widget.communityId);

        if (!mounted) return;
        setState(() {
            _myUserId = me?['id'];
            _community = community;
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
                                        final isAnnouncement = message['isAnnouncement'] == true;

                                        if (isAnnouncement) {
                                            return Align(
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
                                                            Text(message['content'], style: const TextStyle(color: Colors.black87)),
                                                        ],
                                                    ),
                                                ),
                                            );
                                        }

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
                ],
            ),
        );
    }
}
