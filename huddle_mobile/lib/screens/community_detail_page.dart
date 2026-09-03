import 'package:flutter/material.dart';
import '../services/community_service.dart';
import '../services/auth_service.dart';
import '../utils/snackbar_helper.dart';
import 'community_requests_page.dart';
import 'community_chat_page.dart';

class CommunityDetailPage extends StatefulWidget {
    final String communityId;

    const CommunityDetailPage({super.key, required this.communityId});

    @override
    State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
    final _communityService = CommunityService();
    Map<String, dynamic>? _community;
    String? _myUserId;
    bool _isLoading = true;
    bool _isActionLoading = false;
    bool _hasPendingRequest = false; // sadece bu oturumda istek gönderildiyse true olur

    @override
    void initState() {
        super.initState();
        _loadData();
    }

    Future<void> _loadData() async {
        setState(() => _isLoading = true);

        final me = await AuthService().getMe();
        final community = await _communityService.getCommunityById(widget.communityId);

        if (!mounted) return;
        setState(() {
            _myUserId = me?['id'];
            _community = community;
            _isLoading = false;
        });
    }

    bool get _isMember {
        if (_community == null || _myUserId == null) return false;
        final members = List<Map<String, dynamic>>.from(_community!['members']);
        return members.any((m) => m['userId'] == _myUserId);
    }

    bool get _isAdmin {
        if (_community == null || _myUserId == null) return false;
        final members = List<Map<String, dynamic>>.from(_community!['members']);
        final me = members.where((m) => m['userId'] == _myUserId);
        if (me.isEmpty) return false;
        return me.first['role'] == 'Admin';
    }

    Future<void> _join() async {
        setState(() => _isActionLoading = true);
        final result = await _communityService.joinCommunity(widget.communityId);
        if (!mounted) return;
        setState(() => _isActionLoading = false);

        if (result['success'] != true) {
            showAppSnackBar(context, result['message'], color: Colors.red);
            return;
        }

        setState(() => _hasPendingRequest = true);
        showAppSnackBar(context, 'Katılma isteği gönderildi.', color: Colors.green);
    }

    Future<void> _cancelRequest() async {
        setState(() => _isActionLoading = true);
        final result = await _communityService.cancelJoinRequest(widget.communityId);
        if (!mounted) return;
        setState(() => _isActionLoading = false);

        if (result['success'] != true) {
            showAppSnackBar(context, result['message'], color: Colors.red);
            return;
        }

        setState(() => _hasPendingRequest = false);
        showAppSnackBar(context, 'İstek iptal edildi.', color: Colors.green);
    }

    Future<void> _leave() async {
        setState(() => _isActionLoading = true);
        final result = await _communityService.leaveCommunity(widget.communityId);
        if (!mounted) return;
        setState(() => _isActionLoading = false);

        if (result['success'] != true) {
            showAppSnackBar(context, result['message'], color: Colors.red);
            return;
        }

        showAppSnackBar(context, 'Topluluktan ayrıldınız.', color: Colors.green);
        _loadData();
    }

    Future<void> _removeMember(String userId, String displayName) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
            title: const Text('Üyeyi çıkar'),
            content: Text('$displayName kişisini topluluktan çıkarmak istediğine emin misin?'),
            actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Vazgeç'),
                ),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Çıkar', style: TextStyle(color: Colors.red)),
                ),
            ],
        ),
    );

    if (confirmed != true) return;

    final result = await _communityService.removeMember(widget.communityId, userId);
    if (!mounted) return;

    if (result['success'] != true) {
        showAppSnackBar(context, result['message'], color: Colors.red);
        return;
    }

    showAppSnackBar(context, 'Üye topluluktan çıkarıldı.', color: Colors.green);
    _loadData();
    }

    Widget _buildActionButton() {
        if (_isMember) {
            return SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                    onPressed: _isActionLoading ? null : _leave,
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Topluluktan Ayrıl'),
                ),
            );
        }

        if (_hasPendingRequest) {
            return SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                    onPressed: _isActionLoading ? null : _cancelRequest,
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('İsteği İptal Et'),
                ),
            );
        }

        return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: _isActionLoading ? null : _join,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                ),
                child: const Text('Katılma İsteği Gönder'),
            ),
        );
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: const Color(0xFFFAF7F2),
            appBar: AppBar(
                backgroundColor: const Color(0xFFFAF7F2),
                elevation: 0,
                title: Text(_community?['name'] ?? 'Topluluk', style: const TextStyle(color: Color(0xFF1A237E))),
                iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
                actions: [
                    if (_isAdmin)
                        IconButton(
                            onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => CommunityRequestsPage(communityId: widget.communityId),
                                    ),
                                );
                            },
                            icon: const Icon(Icons.person_add_outlined),
                            tooltip: 'Katılım İstekleri',
                        ),
                        if (_isMember)
                            IconButton(
                                onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => CommunityChatPage(communityId: widget.communityId),
                                        ),
                                    );
                                },
                                icon: const Icon(Icons.chat_bubble_outline),
                                tooltip: 'Sohbet',
                            ),
                ],
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _community == null
                    ? const Center(child: Text('Topluluk bulunamadı.'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Center(
                                    child: CircleAvatar(
                                        radius: 40,
                                        backgroundColor: const Color(0xFF1A237E),
                                        backgroundImage: _community!['profilePictureUrl'] != null
                                            ? NetworkImage(_community!['profilePictureUrl'])
                                            : null,
                                        child: _community!['profilePictureUrl'] == null
                                            ? const Icon(Icons.groups, color: Colors.white, size: 36)
                                            : null,
                                    ),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                    child: Text(
                                        _community!['name'],
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                                    ),
                                ),
                                const SizedBox(height: 4),
                                Center(
                                    child: Text(
                                        _community!['ratingCount'] > 0
                                        ? '${_community!['memberCount']} üye · ${_community!['eventCount']} etkinlik · ⭐ ${_community!['averageRating']} (${_community!['ratingCount']})'
                                        : '${_community!['memberCount']} üye · ${_community!['eventCount']} etkinlik',
                                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                ),
                                const SizedBox(height: 16),
                                if ((_community!['description'] as String).isNotEmpty) ...[
                                    Text(_community!['description']),
                                    const SizedBox(height: 16),
                                ],
                                _buildActionButton(),
                                const SizedBox(height: 24),
                                const Text('Üyeler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                                const SizedBox(height: 8),
                                ...List<Map<String, dynamic>>.from(_community!['members']).map((member) {
                                    return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: CircleAvatar(
                                            backgroundColor: const Color(0xFF1A237E),
                                            backgroundImage: member['profilePictureUrl'] != null
                                                ? NetworkImage(member['profilePictureUrl'])
                                                : null,
                                            child: member['profilePictureUrl'] == null
                                                ? const Icon(Icons.person, color: Colors.white, size: 18)
                                                : null,
                                        ),
                                        title: Text(member['displayName']),
                                        trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                            if (member['role'] == 'Admin')
                                                Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                        color: const Color(0xFF1A237E).withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Text('Yönetici', style: TextStyle(fontSize: 12, color: Color(0xFF1A237E))),
                                                    ),
                                                    if (_isAdmin && member['userId'] != _myUserId)
                                                    IconButton(
                                                        onPressed: () => _removeMember(member['userId'], member['displayName']),
                                                        icon: const Icon(Icons.person_remove_outlined, color: Colors.red, size: 20),
                                                        tooltip: 'Topluluktan çıkar',
                                                ),
                                        ],
                                        ),
                                    );
                                }),
                            ],
                        ),
                    ),
        );
    }
}