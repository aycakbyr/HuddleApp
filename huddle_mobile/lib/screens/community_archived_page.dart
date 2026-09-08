import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/community_service.dart';
import 'community_detail_page.dart';
import 'community_chat_page.dart';

class CommunityArchivedPage extends StatefulWidget {
    const CommunityArchivedPage({super.key});

    @override
    State<CommunityArchivedPage> createState() => _CommunityArchivedPageState();
}

class _CommunityArchivedPageState extends State<CommunityArchivedPage> {
    final _communityService = CommunityService();
    final _storage = const FlutterSecureStorage();
    List<Map<String, dynamic>> _archivedCommunities = [];
    bool _isLoading = true;

    @override
    void initState() {
        super.initState();
        _loadData();
    }

    Future<void> _loadData() async {
        setState(() => _isLoading = true);

        final raw = await _storage.read(key: 'archived_communities');
        final archivedIds = raw == null ? <String>{} : Set<String>.from(jsonDecode(raw));
        final allCommunities = await _communityService.getCommunities();

        if (!mounted) return;
        setState(() {
            _archivedCommunities = allCommunities.where((c) => archivedIds.contains(c['id'])).toList();
            _isLoading = false;
        });
    }

    //topluluğu arşivden çıkarır (aynı 'archived_communities' anahtarını communities_page.dart ile paylaşıyoruz)
    Future<void> _unarchive(String communityId) async {
        final raw = await _storage.read(key: 'archived_communities');
        final archivedIds = raw == null ? <String>{} : Set<String>.from(jsonDecode(raw));
        archivedIds.remove(communityId);
        await _storage.write(key: 'archived_communities', value: jsonEncode(archivedIds.toList()));
        _loadData();
    }

    void _openCommunity(Map<String, dynamic> community) {
        if (community['isMember'] == true) {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CommunityChatPage(communityId: community['id'])),
            );
        } else {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CommunityDetailPage(communityId: community['id'])),
            );
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: const Color(0xFFFAF7F2),
            appBar: AppBar(
                backgroundColor: const Color(0xFFFAF7F2),
                elevation: 0,
                iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
                title: const Text('Arşivlenenler', style: TextStyle(color: Color(0xFF1A237E))),
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _archivedCommunities.isEmpty
                    ? const Center(child: Text('Arşivlenmiş topluluk yok.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _archivedCommunities.length,
                        itemBuilder: (context, index) {
                            final community = _archivedCommunities[index];
                            return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _openCommunity(community),
                                    child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                            children: [
                                                CircleAvatar(
                                                    radius: 24,
                                                    backgroundColor: const Color(0xFF1A237E),
                                                    backgroundImage: community['profilePictureUrl'] != null
                                                        ? NetworkImage(community['profilePictureUrl'])
                                                        : null,
                                                    child: community['profilePictureUrl'] == null
                                                        ? const Icon(Icons.groups, color: Colors.white)
                                                        : null,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                    child: Text(
                                                        community['name'],
                                                        style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                            color: Color(0xFF1A237E),
                                                        ),
                                                    ),
                                                ),
                                                IconButton(
                                                    onPressed: () => _unarchive(community['id']),
                                                    icon: const Icon(Icons.unarchive_outlined, color: Color(0xFF1A237E)),
                                                    tooltip: 'Arşivden çıkar',
                                                ),
                                            ],
                                        ),
                                    ),
                                ),
                            );
                        },
                    ),
        );
    }
}
