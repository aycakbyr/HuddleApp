import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/user_service.dart';
import 'event_detail_page.dart';
import 'follow_list_page.dart';
import '../utils/snackbar_helper.dart';

class UserProfilePage extends StatefulWidget {
    final String userId;
    const UserProfilePage({super.key, required this.userId});

    @override
    State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
    final _userService = UserService();
    Map<String, dynamic>? _profile;
    bool _isLoading = true;
    bool _isFollowLoading = false;
    String? _errorMessage;
    List<Map<String, dynamic>> _photos = [];
    List<Map<String, dynamic>> _events = [];
    Map<String, dynamic>? _ratings;

    // instagram tarzı sekmeler: 0 = Anılar, 1 = Etkinlikler, 2 = Değerlendirmeler
    int _selectedTab = 0;

    @override
    void initState() {
        super.initState();
        _load();
    }

    Future<void> _load() async {
        setState(() => _isLoading = true);
        try {
            final profile = await _userService.getProfile(widget.userId);
            if (!mounted) return;
            setState(() {
                _profile = profile;
                _isLoading = false;
            });
            _loadPhotosRatingsAndEvents();
        } catch (e) {
            if (!mounted) return;
            setState(() {
                _errorMessage = 'Profil yüklenemedi.';
                _isLoading = false;
            });
        }
    }

    Future<void> _loadPhotosRatingsAndEvents() async {
        try{
            final photos = await _userService.getUserPhotos(widget.userId);
            if (!mounted) return;
            setState(() => _photos = photos);
        } catch (e) {
            //foto galerisi olmasa bile çalışmaya devam eder
        }
        try{
            final ratings = await _userService.getUserRatings(widget.userId);
            if (!mounted) return;
            setState(() => _ratings = ratings);
        } catch (e) {
            //değerlendirmeler olmasa bile çalışmaya devam eder
        }
        try{
            final events = await _userService.getUserEvents(widget.userId);
            if (!mounted) return;
            setState(() => _events = events);
        } catch (e) {
            //etkinlik listesi olmasa bile çalışmaya devam eder
        }
    }

    Future<void> _toggleFollow() async {
        if (_profile == null) return;
        setState(() => _isFollowLoading = true);

        final isFollowing = _profile!['isFollowedByMe'] == true;
        final result = isFollowing
            ? await _userService.unfollow(widget.userId)
            : await _userService.follow(widget.userId);

        if (!mounted) return;
        setState(() => _isFollowLoading = false);

        if (result['success'] == true) {
            setState(() {
                _profile!['isFollowedByMe'] = !isFollowing;
                _profile!['followerCount'] = (_profile!['followerCount'] ?? 0) + (isFollowing ? -1 : 1);
            });
        } else {
            showAppSnackBar(context, result['message'], color: Colors.red);
        }
    }

    String _formatDate(String? raw) {
        if (raw == null) return '';
        final date = DateTime.parse(raw).toLocal();
        return '${date.day}/${date.month}/${date.year}';
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: const Color(0xFFFAF7F2),
            appBar: AppBar(
                backgroundColor: const Color(0xFFFAF7F2),
                elevation: 0,
                iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
                title: const Text('Profil', style: TextStyle(color: Color(0xFF1A237E), fontSize: 18)),
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null || _profile == null
                    ? Center(child: Text(_errorMessage ?? 'Bir hata oluştu.'))
                    : _buildBody(),
        );
    }

    Widget _buildBody() {
        final profile = _profile!;
        final displayName = profile['displayName'] ?? '?';
        final isMe = profile['isMe'] == true;
        final isFollowing = profile['isFollowedByMe'] == true;

        return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                children: [
                    Center(
                        child: CircleAvatar(
                            radius: 45,
                            backgroundColor: const Color(0xFF1A237E),
                            child: Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontSize: 32),
                            ),
                        ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                        child: Text(displayName, style: GoogleFonts.pacifico(fontSize: 22, color: const Color(0xFF1A237E))),
                    ),
                    if (profile['username'] != null) ...[
                        const SizedBox(height: 4),
                        Center(
                            child: Text('@${profile['username']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            _statColumn(
                                count: profile['followerCount'] ?? 0,
                                label: 'Takipçi',
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => FollowListPage(
                                            userId: widget.userId,
                                            showFollowers: true,
                                            title: '$displayName - Takipçiler',
                                        ),
                                    ),
                                ),
                            ),
                            const SizedBox(width: 24),
                            _statColumn(
                                count: profile['followingCount'] ?? 0,
                                label: 'Takip',
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => FollowListPage(
                                            userId: widget.userId,
                                            showFollowers: false,
                                            title: '$displayName - Takip Edilenler',
                                        ),
                                    ),
                                ),
                            ),
                        ],
                    ),
                    if (!isMe) ...[
                        const SizedBox(height: 20),
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                    onPressed: _isFollowLoading ? null : _toggleFollow,
                                    style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        backgroundColor: isFollowing ? Colors.grey : const Color(0xFF1A237E),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: _isFollowLoading
                                        ? const SizedBox(
                                            height: 18, width: 18,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                        : Text(isFollowing ? 'Takip Ediliyor' : 'Takip Et'),
                                ),
                            ),
                        ),
                    ],
                    const SizedBox(height: 20),

                    // instagram tarzı sekme çubuğu: Anılar / Etkinlikler / Değerlendirmeler
                    Row(
                        children: [
                            _tabButton(0, Icons.photo_library_outlined, 'Anılar'),
                            _tabButton(1, Icons.event_outlined, 'Etkinlikler'),
                            _tabButton(2, Icons.star_outline, 'Değerlendirmeler'),
                        ],
                    ),
                    const Divider(height: 1),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildTabContent(),
                    ),
                ],
            ),
        );
    }

    // sekme başlığı butonu — seçili olan altı çizili ve lacivert
    Widget _tabButton(int index, IconData icon, String label) {
        final selected = _selectedTab == index;
        final color = selected ? const Color(0xFF1A237E) : Colors.grey;
        return Expanded(
            child: GestureDetector(
                onTap: () => setState(() => _selectedTab = index),
                child: Column(
                    children: [
                        Icon(icon, size: 22, color: color),
                        const SizedBox(height: 4),
                        Text(
                            label,
                            style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                            height: 2,
                            color: selected ? const Color(0xFF1A237E) : Colors.transparent,
                        ),
                    ],
                ),
            ),
        );
    }

    Widget _buildTabContent() {
        switch (_selectedTab) {
            case 0:
                return _buildPhotosTab();
            case 1:
                return _buildEventsTab();
            default:
                return _buildRatingsTab();
        }
    }

    // Anılar sekmesi — etkinlik fotoğrafları + profile doğrudan eklenenler, ızgara görünümü
    Widget _buildPhotosTab() {
        return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _photos.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                        child: Text(
                            'Henüz fotoğraf yok.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                    ),
                )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                    ),
                    itemCount: _photos.length,
                    itemBuilder: (context, i) {
                        final photo = _photos[i];
                        return ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                                photo['imageUrl'],
                                fit: BoxFit.cover,
                            ),
                        );
                    },
                ),
        );
    }

    // Etkinlikler sekmesi — bu kullanıcının oluşturduğu etkinlikler
    Widget _buildEventsTab() {
        return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _events.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                        child: Text(
                            'Henüz bir etkinlik oluşturmamış.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                    ),
                )
                : Column(
                    children: _events.map((e) {
                        return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF1A237E).withValues(alpha: 0.1),
                                    child: const Icon(Icons.event, color: Color(0xFF1A237E), size: 20),
                                ),
                                title: Text(
                                    e['title'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                subtitle: Text(
                                    '${e['categoryName'] ?? ''} • ${_formatDate(e['startTime'])} • ${e['participantCount'] ?? 0} katılımcı',
                                    style: const TextStyle(fontSize: 12),
                                ),
                                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => EventDetailPage(eventId: e['id'])),
                                    );
                                },
                            ),
                        );
                    }).toList(),
                ),
        );
    }

    // Değerlendirmeler sekmesi
    Widget _buildRatingsTab() {
        final ratingCount = _ratings?['ratingCount'] ?? 0;
        return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    if (ratingCount > 0)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                                children: [
                                    const Icon(Icons.star, size: 18, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                        '${_ratings!['averageScore']} ($ratingCount değerlendirme)',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A237E)),
                                    ),
                                ],
                            ),
                        ),
                    if (ratingCount == 0)
                        Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                                child: Text(
                                    'Henüz değerlendirme almamış.',
                                    style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                            ),
                        )
                    else
                        ...List<Map<String, dynamic>>.from(_ratings!['ratings'] ?? [])
                            .map((r) => _ratingCard(r)),
                ],
            ),
        );
    }

    Widget _ratingCard(Map<String, dynamic> rating) {
        final score = (rating['score'] ?? 0) as int;
        return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                        children: [
                            Expanded(
                                child: Text(
                                    rating['raterDisplayName'] ?? '?',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                            ),
                            Row(
                                children: List.generate(5, (i) => Icon(
                                    i < score ? Icons.star : Icons.star_border,
                                    size: 14,
                                    color: Colors.amber,
                                )),
                            ),
                        ],
                    ),
                    if (rating['comment'] != null && (rating['comment'] as String).isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                            rating['comment'],
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                    ],
                ],
            ),
        );
    }

    Widget _statColumn({required int count, required String label, required VoidCallback onTap}) {
        return GestureDetector(
            onTap: onTap,
            child: Column(
                children: [
                    Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                    const SizedBox(height: 2),
                    Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
            ),
        );
    }
}
