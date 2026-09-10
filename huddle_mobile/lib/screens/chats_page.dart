import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/direct_message_service.dart';
import '../services/community_service.dart';
import '../utils/chat_date_helper.dart';
import 'direct_chat_page.dart';
import 'community_chat_page.dart';
import 'new_message_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChatsPage extends StatefulWidget {
    const ChatsPage({super.key});

    @override
    State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
    final _messageService = DirectMessageService();
    final _communityService = CommunityService();
    final _storage = const FlutterSecureStorage();
    List<Map<String, dynamic>> _items = []; // dm + topluluk sohbetleri birleşik, en yeniden eskiye
    bool _isLoading = true;
    Timer? _pollTimer;

    @override
    void initState() {
        super.initState();
        _loadAll();
        _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadAll(silent: true));
    }

    @override
    void dispose() {
        _pollTimer?.cancel();
        super.dispose();
    }

    // dm konuşmalarını + üye olunan toplulukları tek, zaman sırasına göre karışık bir gelen kutusunda birleştiriyoruz
    Future<void> _loadAll({bool silent = false}) async {
        if (!silent) setState(() => _isLoading = true);

        try {
            final conversations = await _messageService.getConversations();
            final communities = await _communityService.getCommunities();

            final hiddenRaw = await _storage.read(key: 'hidden_conversations');
            final hidden = hiddenRaw == null
                ? <String, String>{}
                : Map<String, String>.from(jsonDecode(hiddenRaw));

            final archivedRaw = await _storage.read(key: 'archived_communities');
            final archivedIds = archivedRaw == null ? <String>{} : Set<String>.from(jsonDecode(archivedRaw));

            final List<Map<String, dynamic>> merged = [];

            // "sohbeti sil" ile gizlenmiş bir dm, gizlendikten SONRA yeni mesaj geldiyse tekrar listeye döner
            for (final c in conversations) {
                final hiddenAtRaw = hidden[c['otherUserId']];
                if (hiddenAtRaw != null) {
                    final hiddenAt = DateTime.parse(hiddenAtRaw);
                    final lastMessageAt = DateTime.parse(c['lastMessageSentAt']);
                    if (!lastMessageAt.isAfter(hiddenAt)) continue;
                }

                merged.add({
                    'type': 'dm',
                    'id': c['otherUserId'],
                    'displayName': c['otherUserDisplayName'],
                    'pictureUrl': c['otherUserProfilePictureUrl'],
                    'lastMessageContent': c['lastMessageContent'],
                    'lastMessageIsDeleted': c['lastMessageIsDeleted'] == true,
                    'lastMessageSentAt': DateTime.parse(c['lastMessageSentAt']),
                    'isLastMessageMine': c['isLastMessageMine'] == true,
                    'unreadCount': c['unreadCount'] ?? 0,
                });
            }

            // arşivlenmiş topluluklar sohbetler sekmesinde de görünmesin (topluluklar sayfasıyla tutarlı)
            for (final community in communities) {
                if (community['isMember'] != true) continue;
                if (archivedIds.contains(community['id'])) continue;

                final lastSentAtRaw = community['lastMessageSentAt'];
                merged.add({
                    'type': 'community',
                    'id': community['id'],
                    'displayName': community['name'],
                    'pictureUrl': community['profilePictureUrl'],
                    'lastMessageContent': community['lastMessageContent'] ?? '',
                    'lastMessageIsDeleted': community['lastMessageIsDeleted'] == true,
                    'lastMessageSentAt': lastSentAtRaw != null ? DateTime.parse(lastSentAtRaw) : DateTime.fromMillisecondsSinceEpoch(0),
                    'isLastMessageMine': community['isLastMessageMine'] == true,
                    'hasMessages': lastSentAtRaw != null,
                    'unreadCount': community['unreadCount'] ?? 0,
                });
            }

            merged.sort((a, b) => (b['lastMessageSentAt'] as DateTime).compareTo(a['lastMessageSentAt'] as DateTime));

            if (!mounted) return;
            setState(() {
                _items = merged;
                _isLoading = false;
            });
        } catch (e) {
            if (!mounted) return;
            if (!silent) setState(() => _isLoading = false);
        }
    }

    //dm sohbetini kendi ekranından gizler (karşı taraf hala mesajları görmeye devam eder)
    Future<void> _hideConversation(String otherUserId) async {
        final hiddenRaw = await _storage.read(key: 'hidden_conversations');
        final hidden = hiddenRaw == null
            ? <String, String>{}
            : Map<String, String>.from(jsonDecode(hiddenRaw));
        hidden[otherUserId] = DateTime.now().toUtc().toIso8601String();
        await _storage.write(key: 'hidden_conversations', value: jsonEncode(hidden));
        _loadAll();
    }

    //topluluğu sohbetler sekmesinden arşivler (topluluklar sayfasındaki arşivleme ile aynı mekanizma)
    Future<void> _archiveCommunity(String communityId) async {
        final archivedRaw = await _storage.read(key: 'archived_communities');
        final archivedIds = archivedRaw == null ? <String>{} : Set<String>.from(jsonDecode(archivedRaw));
        archivedIds.add(communityId);
        await _storage.write(key: 'archived_communities', value: jsonEncode(archivedIds.toList()));
        _loadAll();
    }

    Future<void> _openNewMessage() async {
        await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewMessagePage()),
        );
        _loadAll();
    }

    Future<void> _openItem(Map<String, dynamic> item) async {
        if (item['type'] == 'dm') {
            await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DirectChatPage(otherUserId: item['id'])),
            );
        } else {
            await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CommunityChatPage(communityId: item['id'])),
            );
        }
        _loadAll();
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
                        : _items.isEmpty
                            ? const Center(child: Text('Henüz sohbetin yok. Yeni bir mesaj başlat!'))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _items.length,
                                itemBuilder: (context, index) {
                                    final item = _items[index];
                                    final isDm = item['type'] == 'dm';
                                    final isDeleted = item['lastMessageIsDeleted'] == true;
                                    final hasMessages = isDm || item['hasMessages'] == true;
                                    final unreadCount = (item['unreadCount'] ?? 0) as int;
                                    final hasUnread = unreadCount > 0;
                                    final preview = !hasMessages
                                        ? 'Henüz mesaj yok'
                                        : (isDeleted
                                            ? 'Bu mesaj silindi'
                                            : (item['isLastMessageMine'] == true
                                                ? 'Sen: ${item['lastMessageContent']}'
                                                : item['lastMessageContent']));

                                    return Dismissible(
                                        key: Key('${item['type']}_${item['id']}'),
                                        direction: DismissDirection.endToStart,
                                        background: Container(
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.only(right: 24),
                                            margin: const EdgeInsets.only(bottom: 12),
                                            decoration: BoxDecoration(
                                                color: Colors.red.shade100,
                                                borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                                isDm ? Icons.delete_outline : Icons.archive_outlined,
                                                color: Colors.red,
                                            ),
                                        ),
                                        onDismissed: (_) => isDm ? _hideConversation(item['id']) : _archiveCommunity(item['id']),
                                        child: Card(
                                            margin: const EdgeInsets.only(bottom: 12),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: InkWell(
                                                borderRadius: BorderRadius.circular(12),
                                                onTap: () => _openItem(item),
                                                child: Padding(
                                                    padding: const EdgeInsets.all(16),
                                                    child: Row(
                                                        children: [
                                                            CircleAvatar(
                                                                radius: 24,
                                                                backgroundColor: const Color(0xFF1A237E),
                                                                backgroundImage: item['pictureUrl'] != null
                                                                    ? NetworkImage(item['pictureUrl'])
                                                                    : null,
                                                                child: item['pictureUrl'] == null
                                                                    ? Icon(isDm ? Icons.person : Icons.groups, color: Colors.white)
                                                                    : null,
                                                            ),
                                                            const SizedBox(width: 12),
                                                            Expanded(
                                                                child: Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                        Text(
                                                                            item['displayName'],
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
                                                                                color: hasUnread ? Colors.black87 : Colors.grey,
                                                                                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                                                                                fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                                                                            ),
                                                                        ),
                                                                    ],
                                                                ),
                                                            ),
                                                            if (hasMessages)
                                                                Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                                    children: [
                                                                        Text(
                                                                            formatMessageTime((item['lastMessageSentAt'] as DateTime).toIso8601String()),
                                                                            style: TextStyle(
                                                                                fontSize: 11,
                                                                                color: hasUnread ? const Color(0xFF25D366) : Colors.grey,
                                                                                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                                                            ),
                                                                        ),
                                                                        if (hasUnread)
                                                                            Padding(
                                                                                padding: const EdgeInsets.only(top: 4),
                                                                                child: Container(
                                                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                                                    decoration: const BoxDecoration(
                                                                                        color: Color(0xFF25D366),
                                                                                        shape: BoxShape.circle,
                                                                                    ),
                                                                                    constraints: const BoxConstraints(minWidth: 20),
                                                                                    child: Text(
                                                                                        unreadCount > 99 ? '99+' : '$unreadCount',
                                                                                        textAlign: TextAlign.center,
                                                                                        style: const TextStyle(
                                                                                            color: Colors.white,
                                                                                            fontSize: 11,
                                                                                            fontWeight: FontWeight.bold,
                                                                                        ),
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                    ],
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
