import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../services/direct_message_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../utils/snackbar_helper.dart';
import '../utils/chat_date_helper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'direct_starred_page.dart';
import 'direct_photos_page.dart';

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
    final _picker = ImagePicker();

    List<Map<String, dynamic>> _messages = [];
    Map<String, dynamic>? _otherUser;
    String? _myUserId;
    bool _isLoading = true;
    bool _isSending = false;
    final _storage = const FlutterSecureStorage();
    String? _wallpaperPath;
    Set<String> _starredIds = {};
    Timer? _pollTimer;
    Timer? _typingPollTimer;
    bool _isOtherUserTyping = false;
    DateTime? _lastTypingNotifiedAt;

    @override
    void initState() {
        super.initState();
        _loadData();
        _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _pollMessages());
        _typingPollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollTypingStatus());
    }

    @override
    void dispose() {
        _pollTimer?.cancel();
        _typingPollTimer?.cancel();
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

    // arka planda sessizce yeni mesajları / okundu tiklerini çeker, ekranı yeniden yüklemeden günceller
    Future<void> _pollMessages() async {
        if (!mounted) return;
        try {
            final fresh = await _messageService.getMessages(widget.otherUserId);
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
            if (fresh[i]['isRead'] != _messages[i]['isRead']) return true;
            if (fresh[i]['isDeleted'] != _messages[i]['isDeleted']) return true;
        }
        return false;
    }

    // karşı tarafın şu an yazıp yazmadığını sorar, sadece değiştiyse ekranı günceller
    Future<void> _pollTypingStatus() async {
        if (!mounted) return;
        final isTyping = await _messageService.getTypingStatus(widget.otherUserId);
        if (!mounted) return;
        if (isTyping != _isOtherUserTyping) {
            setState(() => _isOtherUserTyping = isTyping);
        }
    }

    // metin kutusuna her tuş vuruşunda değil, en fazla 2 saniyede bir "yazıyorum" bildirimi gönderir
    void _onTextChanged(String text) {
        if (text.trim().isEmpty) return;
        final now = DateTime.now();
        if (_lastTypingNotifiedAt != null && now.difference(_lastTypingNotifiedAt!) < const Duration(seconds: 2)) {
            return;
        }
        _lastTypingNotifiedAt = now;
        _messageService.notifyTyping(widget.otherUserId);
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

    Future<void> _pickWallpaper() async {
        final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (picked == null) return;

        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'wallpaper_dm_${widget.otherUserId}.jpg';
        final savedImage = await File(picked.path).copy('${appDir.path}/$fileName');

        await _storage.write(key: 'wallpaper_dm_${widget.otherUserId}', value: savedImage.path);

        if (!mounted) return;
        setState(() => _wallpaperPath = savedImage.path);
        showAppSnackBar(context, 'Duvar kağıdı ayarlandı.');
    }

    void _openStarredMessages() {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DirectStarredPage(otherUserId: widget.otherUserId),
            ),
        );
    }

    void _openPhotos() {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DirectPhotosPage(otherUserId: widget.otherUserId),
            ),
        );
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
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    Text(
                                        _otherUser?['displayName'] ?? 'Sohbet',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Color(0xFF1A237E), fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    if (_isOtherUserTyping)
                                        const Text(
                                            'yazıyor...',
                                            style: TextStyle(color: Colors.green, fontSize: 12, fontStyle: FontStyle.italic),
                                        ),
                                ],
                            ),
                        ),
                    ],
                ),
                iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
                actions: [
                    PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Color(0xFF1A237E)),
                        onSelected: (value) {
                            if (value == 'wallpaper') _pickWallpaper();
                            if (value == 'starred') _openStarredMessages();
                            if (value == 'photos') _openPhotos();
                        },
                        itemBuilder: (context) => [
                            const PopupMenuItem(
                                value: 'photos',
                                child: Row(
                                    children: [
                                        Icon(Icons.photo_library_outlined, color: Color(0xFF1A237E), size: 20),
                                        SizedBox(width: 10),
                                        Text('Fotoğraflar'),
                                    ],
                                ),
                            ),
                            const PopupMenuItem(
                                value: 'wallpaper',
                                child: Row(
                                    children: [
                                        Icon(Icons.wallpaper, color: Color(0xFF1A237E), size: 20),
                                        SizedBox(width: 10),
                                        Text('Duvar Kağıdı Değiştir'),
                                    ],
                                ),
                            ),
                            const PopupMenuItem(
                                value: 'starred',
                                child: Row(
                                    children: [
                                        Icon(Icons.star, color: Colors.orange, size: 20),
                                        SizedBox(width: 10),
                                        Text('Yıldızlı Mesajlar'),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ],
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
                                        final showDaySeparator = index == 0 || !isSameDay(_messages[index - 1]['sentAt'], message['sentAt']);

                                        return Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                                if (showDaySeparator)
                                                    Padding(
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
                                                    ),
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
                                                                    Padding(
                                                                        padding: const EdgeInsets.only(top: 4),
                                                                        child: Row(
                                                                            mainAxisSize: MainAxisSize.min,
                                                                            children: [
                                                                                Text(
                                                                                    formatMessageTime(message['sentAt']),
                                                                                    style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey),
                                                                                ),
                                                                                if (isMe) ...[
                                                                                    const SizedBox(width: 4),
                                                                                    Icon(
                                                                                        message['isRead'] == true ? Icons.done_all : Icons.done,
                                                                                        size: 13,
                                                                                        color: message['isRead'] == true ? Colors.lightBlueAccent : Colors.white70,
                                                                                    ),
                                                                                ],
                                                                            ],
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
                            child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                    children: [
                                        Expanded(
                                            child: TextField(
                                                controller: _textController,
                                                onChanged: _onTextChanged,
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
