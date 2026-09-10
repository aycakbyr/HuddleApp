import 'package:flutter/material.dart';
import '../services/event_service.dart';
import '../services/community_service.dart';
import '../services/user_service.dart';
import 'event_detail_page.dart';
import 'community_detail_page.dart';
import 'community_chat_page.dart';
import 'user_profile_page.dart';

// ana sayfadaki büyüteç ikonuyla açılan genel arama: etkinlik/topluluk/kişi sekmeli
class SearchPage extends StatefulWidget {
    const SearchPage({super.key});

    @override
    State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
    late final TabController _tabController;
    final _searchController = TextEditingController();
    final _eventService = EventService();
    final _communityService = CommunityService();
    final _userService = UserService();

    String _query = '';
    bool _isLoadingData = true; // etkinlik + topluluk listesi ilk açılışta bir kere çekilip client-side filtreleniyor (Keşfet'teki gibi)
    List<Map<String, dynamic>> _allEvents = [];
    List<Map<String, dynamic>> _allCommunities = [];
    List<Map<String, dynamic>> _userResults = [];
    bool _isSearchingUsers = false;

    @override
    void initState() {
        super.initState();
        _tabController = TabController(length: 3, vsync: this);
        _loadInitialData();
    }

    @override
    void dispose() {
        _tabController.dispose();
        _searchController.dispose();
        super.dispose();
    }

    Future<void> _loadInitialData() async {
        try {
            final events = await _eventService.getEvents();
            final communities = await _communityService.getCommunities();
            if (!mounted) return;
            setState(() {
                _allEvents = events;
                _allCommunities = communities;
                _isLoadingData = false;
            });
        } catch (e) {
            if (!mounted) return;
            setState(() => _isLoadingData = false);
        }
    }

    void _onQueryChanged(String value) {
        setState(() => _query = value.trim());
        _searchUsers(_query);
    }

    // kullanıcı araması zaten backend'de var (yeni mesaj ekranındaki gibi), her tuşta çağırıyoruz
    Future<void> _searchUsers(String query) async {
        if (query.isEmpty) {
            setState(() => _userResults = []);
            return;
        }
        setState(() => _isSearchingUsers = true);
        final results = await _userService.searchUsers(query);
        if (!mounted) return;
        setState(() {
            _userResults = results;
            _isSearchingUsers = false;
        });
    }

    List<Map<String, dynamic>> get _filteredEvents {
        if (_query.isEmpty) return [];
        final q = _query.toLowerCase();
        return _allEvents.where((e) => (e['title'] ?? '').toString().toLowerCase().contains(q)).toList();
    }

    List<Map<String, dynamic>> get _filteredCommunities {
        if (_query.isEmpty) return [];
        final q = _query.toLowerCase();
        return _allCommunities.where((c) => (c['name'] ?? '').toString().toLowerCase().contains(q)).toList();
    }

    void _openEvent(String eventId) {
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EventDetailPage(eventId: eventId)),
        );
    }

    // üye olunan topluluğa basınca direkt sohbete, üye olunmayana basınca bilgi/katılma sayfasına git (Topluluklar sekmesiyle aynı mantık)
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

    void _openUser(String userId) {
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UserProfilePage(userId: userId)),
        );
    }

    Widget _emptyState(String text) {
        return Center(child: Text(text, style: const TextStyle(color: Colors.grey)));
    }

    Widget _buildEventResults() {
        if (_isLoadingData) return const Center(child: CircularProgressIndicator());
        final results = _filteredEvents;
        if (results.isEmpty) return _emptyState('Bu aramayla eşleşen etkinlik bulunamadı.');

        return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (context, index) {
                final event = results[index];
                final startTime = DateTime.parse(event['startTime']).toLocal();
                final time = '${startTime.day}/${startTime.month} ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';

                return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                        leading: CircleAvatar(
                            backgroundColor: const Color(0xFF1A237E),
                            backgroundImage: event['imageUrl'] != null ? NetworkImage(event['imageUrl']) : null,
                            child: event['imageUrl'] == null ? const Icon(Icons.event, color: Colors.white) : null,
                        ),
                        title: Text(event['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${event['categoryName'] ?? ''} · $time · ${event['address'] ?? ''}'),
                        onTap: () => _openEvent(event['id']),
                    ),
                );
            },
        );
    }

    Widget _buildCommunityResults() {
        if (_isLoadingData) return const Center(child: CircularProgressIndicator());
        final results = _filteredCommunities;
        if (results.isEmpty) return _emptyState('Bu aramayla eşleşen topluluk bulunamadı.');

        return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (context, index) {
                final community = results[index];
                return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                        leading: CircleAvatar(
                            backgroundColor: const Color(0xFF1A237E),
                            backgroundImage: community['profilePictureUrl'] != null
                                ? NetworkImage(community['profilePictureUrl'])
                                : null,
                            child: community['profilePictureUrl'] == null
                                ? const Icon(Icons.groups, color: Colors.white)
                                : null,
                        ),
                        title: Text(community['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${community['memberCount'] ?? 0} üye'),
                        trailing: community['isMember'] == true
                            ? const Text('Üyesin', style: TextStyle(color: Color(0xFF25D366), fontSize: 12))
                            : null,
                        onTap: () => _openCommunity(community),
                    ),
                );
            },
        );
    }

    Widget _buildUserResults() {
        if (_isSearchingUsers) return const Center(child: CircularProgressIndicator());
        if (_userResults.isEmpty) return _emptyState('Bu aramayla eşleşen kişi bulunamadı.');

        return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _userResults.length,
            itemBuilder: (context, index) {
                final user = _userResults[index];
                return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                        leading: CircleAvatar(
                            backgroundColor: const Color(0xFF1A237E),
                            backgroundImage: user['profilePictureUrl'] != null
                                ? NetworkImage(user['profilePictureUrl'])
                                : null,
                            child: user['profilePictureUrl'] == null ? const Icon(Icons.person, color: Colors.white) : null,
                        ),
                        title: Text(user['displayName'] ?? ''),
                        subtitle: Text('@${user['username'] ?? ''}'),
                        onTap: () => _openUser(user['id']),
                    ),
                );
            },
        );
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: const Color(0xFFFAF7F2),
            appBar: AppBar(
                backgroundColor: const Color(0xFFFAF7F2),
                elevation: 0,
                iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
                title: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: _onQueryChanged,
                    decoration: const InputDecoration(
                        hintText: 'Etkinlik, topluluk veya kişi ara...',
                        border: InputBorder.none,
                    ),
                ),
                bottom: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF1A237E),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF1A237E),
                    tabs: const [
                        Tab(text: 'Etkinlikler'),
                        Tab(text: 'Topluluklar'),
                        Tab(text: 'Kişiler'),
                    ],
                ),
            ),
            body: _query.isEmpty
                ? _emptyState('Aramaya başlamak için yukarıya yaz.')
                : TabBarView(
                    controller: _tabController,
                    children: [
                        _buildEventResults(),
                        _buildCommunityResults(),
                        _buildUserResults(),
                    ],
                ),
        );
    }
}
