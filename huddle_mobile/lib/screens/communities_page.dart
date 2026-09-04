import 'package:flutter/material.dart';
import '../services/community_service.dart';
import 'create_community_page.dart';
import 'community_detail_page.dart';
import 'community_chat_page.dart';

class CommunitiesPage extends StatefulWidget {
    const CommunitiesPage({super.key});

    @override
    State<CommunitiesPage> createState() => _CommunitiesPageState();
}

class _CommunitiesPageState extends State<CommunitiesPage> {
    final _communityService = CommunityService();
    List<Map<String, dynamic>> _communities = [];
    bool _isLoading = true;
    String? _errorMessage;

    @override
    void initState() {
        super.initState();
        _loadCommunities();
    }

    Future<void> _loadCommunities() async {
        setState(() {
            _isLoading = true;
            _errorMessage = null;
        });
        try {
            final communities = await _communityService.getCommunities();
            if (!mounted) return;
            setState(() {
                _communities = communities;
                _isLoading = false;
            });
        } catch (e) {
            if (!mounted) return;
            setState(() {
                _errorMessage = 'Topluluklar yüklenemedi.';
                _isLoading = false;
            });
        }
    }

    Future<void> _openCreateCommunity() async {
        final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateCommunityPage()),
        );

        if (result == true) {
            _loadCommunities();
        }
    }

    // üye olunan topluluğa basınca direkt sohbete, üye olunmayana basınca bilgi/katılma sayfasına git
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
        return Column(
            children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                            onPressed: _openCreateCommunity,
                            style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: const Color(0xFF1A237E),
                                foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Topluluk Oluştur'),
                        ),
                    ),
                ),
                Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                            ? Center(child: Text(_errorMessage!))
                            : _communities.isEmpty
                                ? const Center(child: Text('Henüz topluluk yok.'))
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: _communities.length,
                                    itemBuilder: (context, index) {
                                        final community = _communities[index];
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
                                                                child: Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                        Text(
                                                                            community['name'],
                                                                            style: const TextStyle(
                                                                                fontSize: 16,
                                                                                fontWeight: FontWeight.bold,
                                                                                color: Color(0xFF1A237E),
                                                                            ),
                                                                        ),
                                                                        const SizedBox(height: 4),
                                                                        Row(
                                                                            children: [
                                                                                const Icon(Icons.people, size: 14, color: Colors.grey),
                                                                                const SizedBox(width: 4),
                                                                                Text(
                                                                                    '${community['memberCount']} üye',
                                                                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                                                                ),
                                                                            ],
                                                                        ),
                                                                    ],
                                                                ),
                                                            ),
                                                            Icon(
                                                                community['isMember'] == true
                                                                    ? Icons.chat_bubble_outline
                                                                    : Icons.chevron_right,
                                                                color: Colors.grey,
                                                            ),
                                                        ],
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
