import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'explore_page.dart';
import 'map_page.dart';
import 'create_event_page.dart';
import 'profile_page.dart';
import 'requests_page.dart';
import '../services/event_service.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'communities_page.dart';

class HomePage extends StatefulWidget {
    const HomePage({super.key});

    @override
    State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
    int _currentIndex = 0;
    final _eventService = EventService();
    int _pendingRequestCount = 0;
    String? _displayName;
    String? _profilePictureUrl;

    final List<Widget> _pages = [
        const ExplorePage(),
        const MapPage(),
        const SizedBox(),
        const CommunitiesPage(),
        const Center(child: Text('Sohbet')),
    ];

    @override
    void initState() {
        super.initState();
        _loadPendingRequestCount();
        _loadMe();
    }

    Future<void> _loadMe() async {
        final me = await AuthService().getMe();
        if (!mounted || me == null) return;
        setState(() {
            _displayName = me['displayName'];
            _profilePictureUrl = me['profilePictureUrl'];
        });
    }

    // etkinliklerime gelen bekleyen katılım isteği sayısını yükler (bildirim rozeti için)
    Future<void> _loadPendingRequestCount() async {
        try {
            final requests = await _eventService.getMyPendingRequests();
            if (!mounted) return;
            setState(() => _pendingRequestCount = requests.length);
        } catch (e) {
            // sessizce geç, rozet gösterilmez
        }
    }

    void _openProfile() {
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
        ).then((_) {
            _loadPendingRequestCount();
            _loadMe();
        });
    }

    void _openRequests() {
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RequestsPage()),
        ).then((_) => _loadPendingRequestCount());
    }

    //oturum kapatma işlemini yapan kısım
    Future<void> _logout() async {
        final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text('Oturum kapat'),
                content: const Text('Oturum kapatmak istediğinize emin misiniz?'),
                actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Vazgeç'),
                    ),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Oturum Kapat', style: TextStyle(color: Colors.red)),
                    ),
                ],
            ),
        );

        if (confirmed != true) return;

        await AuthService().logout();
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
        );
    }

    @override
    Widget build(BuildContext context) {
        return Stack(
            children: [
            Scaffold(
            backgroundColor: const Color(0xFFFAF7F2),
            appBar: AppBar(
                backgroundColor: const Color(0xFFFAF7F2),
                elevation: 0,
                title: PopupMenuButton<String>(
                    tooltip: '',
                    offset: const Offset(0, 30),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) {
                        if (value == 'profil') _openProfile();
                        if (value == 'istekler') _openRequests();
                        if (value == 'cikis') _logout();
                    },
                    itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: 'profil',
                            child: Row(
                                children: [
                                    Icon(Icons.person_outline, color: Color(0xFF1A237E), size: 20),
                                    SizedBox(width: 10),
                                    Text('Profil'),
                                ],
                            ),
                        ),
                        PopupMenuItem(
                            value: 'istekler',
                            child: Row(
                                children: [
                                    const Icon(Icons.notifications_outlined, color: Color(0xFF1A237E), size: 20),
                                    const SizedBox(width: 10),
                                    const Text('İstekler'),
                                    if (_pendingRequestCount > 0) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                            child: Text(
                                                '$_pendingRequestCount',
                                                style: const TextStyle(color: Colors.white, fontSize: 10),
                                            ),
                                        ),
                                    ],
                                ],
                            ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                            value: 'cikis',
                            child: Row(
                                children: [
                                    Icon(Icons.logout, color: Colors.red, size: 20),
                                    SizedBox(width: 10),
                                    Text( 'Oturum Kapat', style: TextStyle(color: Colors.red)),
                                ],
                            ),
                        ),
                    ],
                    child: Row(
                        children: [
                            CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF1A237E),
                                backgroundImage: _profilePictureUrl != null
                                    ? NetworkImage(_profilePictureUrl!)
                                    : null,
                                child: _profilePictureUrl == null
                                    ? const Icon(Icons.person, color: Colors.white, size: 16)
                                    : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                                _displayName ?? 'Profil',
                                style: GoogleFonts.pacifico(
                                    fontSize: 18,
                                    color: const Color(0xFF1A237E),
                                ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1A237E)),
                        ],
                    ),
                ),
                actions: [
                    IconButton(
                        onPressed: () {}, //ilerde arama 
                        icon: const Icon(Icons.search, color: Color(0xFF1A237E)),
                    ),
                    Stack(
                        clipBehavior: Clip.none,
                        children: [
                            IconButton(
                                onPressed: _openRequests, //katılım istekleri (bildirimler)
                                icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1A237E)),
                            ),
                            if (_pendingRequestCount > 0)
                                Positioned(
                                    right: 6,
                                    top: 6,
                                    child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                        child: Text(
                                            '$_pendingRequestCount',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(color: Colors.white, fontSize: 10),
                                        ),
                                    ),
                                ),
                        ],
                    ),
                ],
            ),
            body: _pages[_currentIndex],

            bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: _currentIndex,
                onTap: (index) {
                    if(index == 2){
                        // + basınca etkinlik oluşturm
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CreateEventPage()),
                            );
                            return;
                           }  
                           setState(() => _currentIndex = index);
                },
                selectedItemColor: const Color(0xFF1A237E),
                unselectedItemColor: Colors.grey,
                backgroundColor: Colors.white,
                items: [
                    const BottomNavigationBarItem(
                        icon: Icon(Icons.explore_outlined),
                        activeIcon: Icon(Icons.explore),
                        label: 'Keşfet',
                    ),
                    const BottomNavigationBarItem(
                        icon: Icon(Icons.map_outlined),
                        activeIcon: Icon(Icons.map),
                        label: 'Harita',
                    ),
                    const BottomNavigationBarItem(
                        icon: SizedBox(height: 24),
                        label: '',
                    ),
                    const BottomNavigationBarItem(
                        icon: Icon(Icons.group_outlined),
                        activeIcon: Icon(Icons.groups),
                        label: 'Topluluklar',
                    ),
                    const BottomNavigationBarItem(
                        icon: Icon(Icons.chat_bubble_outline),
                        activeIcon: Icon(Icons.chat_bubble),
                        label: 'Sohbet',
                    ),
                ],
            ),
            ),
            Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 26,
                left: 0,
                right: 0,
                child: Center(
                    child: SizedBox(
                        height: 60,
                        width: 60,
                        child: FloatingActionButton(
                            onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const CreateEventPage()),
                                );
                            },
                            backgroundColor: const Color(0xFF1A237E),
                            shape: const CircleBorder(),
                            elevation: 4,
                            child: const Icon(Icons.add, color: Colors.white, size: 32),
                        ),
                    ),
                ),
            ),
            ],
        );
    }
}