import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/direct_message_service.dart';
import 'direct_chat_page.dart';
import 'new_message_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChatsPage extends StatefulWidget {
    const ChatsPage({super.key});

    @override
    State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
    final _messageService = DirectMessageService();
    final _storage = const FlutterSecureStorage();
    List<Map<String, dynamic>> _conversations = [];
    bool _isLoading = true;

    @override
    void initState() {
        super.initState();
        _loadConversations();
    }

    Future<void> _loadConversations() async {
        setState(() => _isLoading = true);

        final all = await _messageService.getConversations();
        final hiddenRaw = await _storage.read(key: 'hidden_conversations');
        final hidden = hiddenRaw == null
            ? <String, String>{}
            : Map<String, String>.from(jsonDecode(hiddenRaw));

        // "sohbeti sil" ile gizlenmiş bir konuşma, gizlendikten SONRA yeni mesaj geldiyse tekrar listeye döner
        final visible = all.where((c) {
            final hiddenAtRaw = hidden[c['otherUserId']];
            if (hiddenAtRaw == null) return true;
            final hiddenAt = DateTime.parse(hiddenAtRaw);
            final lastMessageAt = DateTime.parse(c['lastMessageSentAt']);
            return lastMessageAt.isAfter(hiddenAt);
        }).toList();

        if (!mounted) return;
        setState(() {
            _conversations = visible;
            _isLoading = false;
        });
    }

    //sohbeti kendi ekranından gizler (karşı taraf hala mesajları görmeye devam eder)
    Future<void> _hideConversation(String otherUserId) async {
        final hiddenRaw = await _storage.read(key: 'hidden_conversations');
        final hidden = hiddenRaw == null
            ? <String, String>{}
            : Map<String, String>.from(jsonDecode(hiddenRaw));
        hidden[otherUserId] = DateTime.now().toUtc().toIso8601String();
        await _storage.write(key: 'hidden_conversations', value: jsonEncode(hidden));
        _loadConversations();
    }

    Future<void> _openNewMessage() async {
        await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewMessagePage()),
        );
        _loadConversations();
    }

    Future<void> _openChat(String otherUserId) async {
        await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DirectChatPage(otherUserId: otherUserId)),
        );
        _loadConversations();
    }

    @override
    Widget build(BuildContext context) {
        return Column(
            children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                            onPressed: _openNewMessage,
                            style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: const Color(0xFF1A237E),
                                foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Yeni Mesaj'),
                        ),
                    ),
                ),
                Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _conversations.isEmpty
                            ? const Center(child: Text('Henüz sohbetin yok. Yeni bir mesaj başlat!'))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _conversations.length,
                                itemBuilder: (context, index) {
                                    final conversation = _conversations[index];
                                    final isDeleted = conversation['lastMessageIsDeleted'] == true;
                                    final preview = isDeleted
                                        ? 'Bu mesaj silindi'
                                        : (conversation['isLastMessageMine'] == true
                                            ? 'Sen: ${conversation['lastMessageContent']}'
                                            : conversation['lastMessageContent']);

                                    return Dismissible(
                                        key: Key(conversation['otherUserId']),
                                        direction: DismissDirection.endToStart,
                                        background: Container(
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.only(right: 24),
                                            margin: const EdgeInsets.only(bottom: 12),
                                            decoration: BoxDecoration(
                                                color: Colors.red.shade100,
                                                borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(Icons.delete_outline, color: Colors.red),
                                        ),
                                        onDismissed: (_) => _hideConversation(conversation['otherUserId']),
                                        child: Card(
                                            margin: const EdgeInsets.only(bottom: 12),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: InkWell(
                                                borderRadius: BorderRadius.circular(12),
                                                onTap: () => _openChat(conversation['otherUserId']),
                                                child: Padding(
                                                    padding: const EdgeInsets.all(16),
                                                    child: Row(
                                                        children: [
                                                            CircleAvatar(
                                                                radius: 24,
                                                                backgroundColor: const Color(0xFF1A237E),
                                                                backgroundImage: conversation['otherUserProfilePictureUrl'] != null
                                                                    ? NetworkImage(conversation['otherUserProfilePictureUrl'])
                                                                    : null,
                                                                child: conversation['otherUserProfilePictureUrl'] == null
                                                                    ? const Icon(Icons.person, color: Colors.white)
                                                                    : null,
                                                            ),
                                                            const SizedBox(width: 12),
                                                            Expanded(
                                                                child: Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                        Text(
                                                                            conversation['otherUserDisplayName'],
                                                                            style: const TextStyle(
                                                                                fontSize: 16,
                                                                                fontWeight: FontWeight.bold,
                                                                                color: Color(0xFF1A237E),
                                                                            ),
                                                                        ),
                                                                        const SizedBox(height: 4),
                                                                        Text(
                                                                            preview,
                                                                            maxLines: 1,
                                                                            overflow: TextOverflow.ellipsis,
                                                                            style: TextStyle(
                                                                                color: Colors.grey,
                                                                                fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                                                                            ),
                                                                        ),
                                                                    ],
                                                                ),
                                                            ),
                                                        ],
                                                    ),
                                                ),
                                            ),
                                        ),
                                    );
                                },
                            ),
                ),
            ],
        );
    }
}
