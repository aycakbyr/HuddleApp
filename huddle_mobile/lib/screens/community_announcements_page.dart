import 'package:flutter/material.dart';
import '../services/message_service.dart';

class CommunityAnnouncementsPage extends StatefulWidget {
    final String communityId;

    const CommunityAnnouncementsPage({super.key, required this.communityId});

    @override
    State<CommunityAnnouncementsPage> createState() => _CommunityAnnouncementsPageState();
}

class _CommunityAnnouncementsPageState extends State<CommunityAnnouncementsPage> {
    final _messageService = MessageService();
    List<Map<String, dynamic>> _announcements = [];
    bool _isLoading = true;

    @override
    void initState() {
        super.initState();
        _loadAnnouncements();
    }

    Future<void> _loadAnnouncements() async {
        setState(() => _isLoading = true);

        try {
            final messages = await _messageService.getMessages(widget.communityId);
            final announcements = messages.where((m) => m['isAnnouncement'] == true).toList();
            announcements.sort((a, b) => b['sentAt'].compareTo(a['sentAt'])); // en yeni en üstte
            if (!mounted) return;
            setState(() {
                _announcements = announcements;
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
                title: const Text('Duyurular', style: TextStyle(color: Color(0xFF1A237E))),
                iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _announcements.isEmpty
                    ? const Center(
                        child: Text('Henüz duyuru yok.', style: TextStyle(color: Colors.grey)),
                    )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _announcements.length,
                        itemBuilder: (context, i) {
                            final announcement = _announcements[i];
                            return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.amber.shade300),
                                ),
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        Row(
                                            children: [
                                                const Icon(Icons.campaign, size: 16, color: Colors.orange),
                                                const SizedBox(width: 6),
                                                Text(
                                                    announcement['senderDisplayName'],
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
                                                ),
                                            ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(announcement['content'], style: const TextStyle(color: Colors.black87)),
                                    ],
                                ),
                            );
                        },
                    ),
        );
    }
}