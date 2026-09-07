import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/message_service.dart';

class CommunityStarredPage extends StatefulWidget {
    final String communityId;

    const CommunityStarredPage({super.key, required this.communityId});

    @override
    State<CommunityStarredPage> createState() => _CommunityStarredPageState();
}

class _CommunityStarredPageState extends State<CommunityStarredPage> {
    final _messageService = MessageService();
    final _storage = const FlutterSecureStorage();
    List<Map<String, dynamic>> _starredMessages = [];
    bool _isLoading = true;

    @override
    void initState() {
        super.initState();
        _loadStarred();
    }

    Future<void> _loadStarred() async {
        setState(() => _isLoading = true);
        try {
            final raw = await _storage.read(key: 'starred_${widget.communityId}');
            final starredIds = raw == null ? <String>{} : Set<String>.from(jsonDecode(raw));

            final messages = await _messageService.getMessages(widget.communityId);
            final starredMessages = messages.where((m) => starredIds.contains(m['id'])).toList();
            starredMessages.sort((a, b) => b['sentAt'].compareTo(a['sentAt'])); // en yeni en üstte

            if (!mounted) return;
            setState(() {
                _starredMessages = starredMessages;
                _isLoading = false;
            });
        } catch (e) {
            if (!mounted) return;
            setState(() => _isLoading = false);
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: const Color(0xFFFAF7F2),
            appBar: AppBar(
                backgroundColor: const Color(0xFFFAF7F2),
                elevation: 0,
                title: const Text('Yıldızlı Mesajlar', style: TextStyle(color: Color(0xFF1A237E))),
                iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _starredMessages.isEmpty
                    ? const Center(
                        child: Text('Henüz yıldızladığın bir mesaj yok.', style: TextStyle(color: Colors.grey)),
                    )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _starredMessages.length,
                        itemBuilder: (context, i) {
                            final message = _starredMessages[i];
                            return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        Row(
                                            children: [
                                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                                const SizedBox(width: 6),
                                                Text(
                                                    message['senderDisplayName'],
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                                                ),
                                            ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(message['content'], style: const TextStyle(color: Colors.black87)),
                                    ],
                                ),
                            );
                        },
                    ),
        );
    }
}
