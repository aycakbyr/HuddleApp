import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../services/user_service.dart';
import 'event_detail_page.dart';
import 'login_page.dart';
import 'settings_page.dart';
import 'follow_list_page.dart';
import 'user_profile_page.dart';
import '../utils/snackbar_helper.dart';

class ProfilePage extends StatefulWidget {
    const ProfilePage({super.key});

    @override
    State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
    final _authService = AuthService();
    final _eventService = EventService();
    final _userService = UserService();
    final _picker = ImagePicker();

    Map<String, dynamic>? _me;
    List<Map<String, dynamic>> _myEvents = [];
    List<Map<String, dynamic>> _joinedEvents = [];
    List<Map<String, dynamic>> _photos = [];
    Map<String, dynamic>? _ratings;
    bool _isLoading = true;
    bool _isUploadingPhoto = false;
    bool _isUpdatingPicture = false;
    

    // instagram tarzı sekmeler: 0 = Anılar, 1 = Etkinliklerim, 2 = Değerlendirmeler
    int _selectedTab = 0;
    // etkinlik sekmesi alt seçin 0=oluşturulan 1=katıldığım
    int _eventsSubTab = 0;

    @override
    void initState() {
        super.initState();
        _loadAll();
    }

    Future<void> _loadAll() async {
        setState(() => _isLoading = true);
        try {
            final results = await Future.wait<dynamic>([
                _authService.getMe(),
                _eventService.getMyEvents(),
                _eventService.getJoinedEvents(),
            ]);
            if (!mounted) return;
            setState(() {
                _me = results[0] as Map<String, dynamic>?;
                _myEvents = results[1] as List<Map<String, dynamic>>;
                _joinedEvents = results[2] as List<Map<String, dynamic>>;
                _isLoading = false;
            });
            _loadPhotosAndRatings();
        } catch (e) {
            if (!mounted) return;
            setState(() => _isLoading = false);
        }
    }

    // profilimdeki anı fotoğrafları ve aldığım değerlendirmeler (başkalarının gördüğü gibi)
    Future<void> _loadPhotosAndRatings() async {
        final myId = _me?['id'];
        if (myId == null) return;
        try {
            final photos = await _userService.getUserPhotos(myId);
            if (!mounted) return;
            setState(() => _photos = photos);
        } catch (e) {
            // foto galerisi olmasa bile çalışmaya devam eder
        }
        try {
            final ratings = await _userService.getUserRatings(myId);
            if (!mounted) return;
            setState(() => _ratings = ratings);
        } catch (e) {
            // değerlendirmeler olmasa bile çalışmaya devam eder
        }
    }

    //profil foto değiştirme
    Future<void> _pickAndUpdateProfilePicture() async {
        final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (picked == null) return;

        setState(() => _isUpdatingPicture = true);
        final result = await _userService.updateProfilePicture(File(picked.path));
        if (!mounted) return;
        setState(() => _isUpdatingPicture = false );

        if (result['success'] == true) {
            setState(() {
                _me?['profilePictureUrl'] = result['data']['imageUrl'];
            });
        } else {
            showAppSnackBar(context,result['message'], color: Colors.red);
        }
    }

    // profile doğrudan (bir etkinliğe bağlı olmadan) fotoğraf ekleme — sadece kendi profilimde görünür
    Future<void> _pickAndUploadProfilePhoto() async {
        final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (picked == null) return;

        setState(() => _isUploadingPhoto = true);
        final result = await _userService.uploadProfilePhoto(File(picked.path));
        if (!mounted) return;
        setState(() => _isUploadingPhoto = false);

        if (result['success'] == true) {
            _loadPhotosAndRatings();
        } else {
            showAppSnackBar(context, result['message'], color: Colors.red);
        }
    }

    Future<void> _editUsername() async {
    final controller = TextEditingController(text: _me?['username'] ?? '');
    String? errorText;

    await showDialog(
        context: context,
        builder: (context) {
            return StatefulBuilder(
                builder: (context, setDialogState) {
                    return AlertDialog(
                        title: const Text('Kullanıcı adını değiştir'),
                        content: TextField(
                            controller: controller,
                            autofocus: true,
                            decoration: InputDecoration(
                                prefixText: '@',
                                border: const OutlineInputBorder(),
                                errorText: errorText,
                                hintText: 'kullanici_adi',
                            ),
                        ),
                        actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Vazgeç'),
                            ),
                            TextButton(
                                onPressed: () async {
                                    final result = await _authService.updateUsername(controller.text.trim());
                                    if (result['success'] == true) {
                                        if (!mounted) return;
                                        Navigator.pop(context);
                                        setState(() {
                                            _me = {..._me ?? {}, 'username': result['data']['username']};
                                        });
                                    } else {
                                        setDialogState(() => errorText = result['message']);
                                    }
                                },
                                child: const Text('Kaydet'),
                            ),
                        ],
                    );
                },
            );
        },
    );
    }

    void _openAccountSheet() {
        showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
                return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            const Text(
                                'Hesap',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                            ),
                            const SizedBox(height: 16),
                            _accountRow(Icons.person_outline, 'Ad Soyad', _me?['displayName'] ?? '-'),
                            const SizedBox(height: 12),
                            _accountRow(Icons.email_outlined, 'E-posta', _me?['email'] ?? '-'),
                            const SizedBox(height: 12),
                            _accountRow(Icons.wc, 'Cinsiyet', _me?['gender'] ?? '-'),
                            const SizedBox(height: 20),
                        ],
                    ),
                );
            },
        );
    }

    Widget _accountRow(IconData icon, String label, String value) {
        return Row(
            children: [
                Icon(icon, size: 20, color: const Color(0xFF1A237E)),
                const SizedBox(width: 12),
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const Spacer(),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            ],
        );
    }

    Future<void> _confirmLogout() async {
        final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text('Oturumu kapat'),
                content: const Text('Oturumu kapatmak istediğine emin misin?'),
                actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Vazgeç'),
                    ),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Oturumu Kapat', style: TextStyle(color: Colors.red)),
                    ),
                ],
            ),
        );

        if (confirmed != true) return;

        await _authService.logout();
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
        );
    }

    String _formatDate(String? raw) {
        if (raw == null) return '';
        final date = DateTime.parse(raw).toLocal();
        return '${date.day}/${date.month}/${date.year}';
    }

    @override
    Widget build(BuildContext context) {
        final displayName = _me?['displayName'] ?? 'Ayça';
        final email = _me?['email'] ?? '';

        return Scaffold(
            backgroundColor: const Color(0xFFFAF7F2),
            appBar: AppBar(
                backgroundColor: const Color(0xFFFAF7F2),
                elevation: 0,
                iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
                title: const Text(
                    '',
                    style: TextStyle(color: Color(0xFF1A237E), fontSize: 18),
                ),
                actions: [
                    PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Color(0xFF1A237E)),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) {
                            if (value == 'profili_goruntule') {
                                if (_me == null) return;
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => UserProfilePage(userId: _me!['id']),
                                    ),
                                );
                            }
                            if (value == 'hesap') _openAccountSheet();
                            if (value == 'ayarlar') {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                                );
                            }
                            if (value == 'cikis') _confirmLogout();
                        },
                        itemBuilder: (context) => [
                            const PopupMenuItem(
                                value: 'profili_goruntule',
                                child: Row(
                                    children: [
                                        Icon(Icons.visibility_outlined, color: Color(0xFF1A237E), size: 20),
                                        SizedBox(width: 10),
                                        Text('Profili Görüntüle'),
                                    ],
                                ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                                value: 'hesap',
                                child: Row(
                                    children: [
                                        Icon(Icons.person_outline, color: Color(0xFF1A237E), size: 20),
                                        SizedBox(width: 10),
                                        Text('Hesap'),
                                    ],
                                ),
                            ),
                            const PopupMenuItem(
                                value: 'ayarlar',
                                child: Row(
                                    children: [
                                        Icon(Icons.settings_outlined, color: Color(0xFF1A237E), size: 20),
                                        SizedBox(width: 10),
                                        Text('Ayarlar'),
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
                                        Text('Oturum Kapat', style: TextStyle(color: Colors.red)),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ],
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadAll,
                    child: ListView(
                        padding: const EdgeInsets.only(top: 16, bottom: 24),
                        children: [
                            // Üst profil başlığı — instagram tarzı, ortalanmış
                            Center(
                                child: Stack(
                                    children: [
                                        CircleAvatar(
                                            radius: 45,
                                            backgroundColor: const Color(0xFF1A237E),
                                            backgroundImage: _me?['profilePictureUrl'] != null
                                                ? NetworkImage(_me!['profilePictureUrl'])
                                                : null,
                                            child: _me?['profilePictureUrl'] == null
                                                ? Text (
                                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                                    style: const TextStyle(color: Colors.white, fontSize: 32),
                                                ) 
                                                : null,
                                        ),
                                        Positioned( //sağ alt köşeye sabitleme
                                            bottom: 0,
                                            right: 0,
                                            child: GestureDetector(
                                                onTap: _isUpdatingPicture ? null : _pickAndUpdateProfilePicture,
                                                child: Container(
                                                    width: 30,
                                                    height: 30,
                                                    decoration: BoxDecoration(
                                                        color: const Color(0xFF1A237E),
                                                        shape: BoxShape.circle,
                                                        border: Border.all(color: const Color(0xFFFAF7F2), width: 2),
                                                    ),
                                                    child: _isUpdatingPicture
                                                        ? const Padding(
                                                            padding: EdgeInsets.all(6),
                                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                                        )
                                                        : const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                                ),
                                            ),
                                        ),
                                    ],
                                ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                                child: Text(
                                    displayName,
                                    style: GoogleFonts.pacifico(fontSize: 22, color: const Color(0xFF1A237E)),
                                ),
                            ),
                            const SizedBox(height: 4),
                            Center(
                                child: GestureDetector(
                                    onTap: _editUsername,
                                    child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                            Text(
                                               '@${_me?['username'] ?? '...'}',
                                               style: const TextStyle(color: Colors.grey, fontSize: 13),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.edit, size: 14, color: Colors.grey),
                                        ],
                                    ),
                                ),
                            ),
                            if (email.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Center(
                                    child: Text(email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    GestureDetector(
                                        onTap: () {
                                            if (_me == null) return;
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) => FollowListPage(
                                                        userId: _me!['id'],
                                                        showFollowers: true,
                                                        title: 'Takipçiler',
                                                    ),
                                                ),
                                            );
                                        },
                                        child: Row(
                                            children: [
                                                Text(
                                                    '${_me?['followerCount'] ?? 0}',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A237E)),
                                                ),
                                                const SizedBox(width: 4),
                                                const Text('Takipçi', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                            ],
                                        ),
                                    ),
                                    const SizedBox(width: 24),
                                    GestureDetector(
                                        onTap: () {
                                            if (_me == null) return;
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) => FollowListPage(
                                                        userId: _me!['id'],
                                                        showFollowers: false,
                                                        title: 'Takip Edilenler',
                                                    ),
                                                ),
                                            );
                                        },
                                        child: Row(
                                            children: [
                                                Text(
                                                    '${_me?['followingCount'] ?? 0}',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A237E)),
                                                ),
                                                const SizedBox(width: 4),
                                                const Text('Takip', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                            ],
                                        ),
                                    ),
                                ],
                            ),
                            const SizedBox(height: 20),

                            // instagram tarzı sekme çubuğu: Anılar / Etkinliklerim / Değerlendirmeler
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
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                        children: [
                            Text(
                                '${_photos.length} fotoğraf',
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                            const Spacer(),
                            IconButton(
                                onPressed: _isUploadingPhoto ? null : _pickAndUploadProfilePhoto,
                                icon: _isUploadingPhoto
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                    : const Icon(Icons.add_circle_outline, color: Color(0xFF1A237E)),
                                tooltip: 'Fotoğraf ekle',
                            ),
                        ],
                    ),
                    if (_photos.isEmpty)
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                                child: Text(
                                    'Henüz fotoğraf eklemedin.',
                                    style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                            ),
                        )
                    else
                        GridView.builder(
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
                ],
            ),
        );
    }

        // Etkinlikler sekmesi
    Widget _buildEventsTab() {
        final activeList = _eventsSubTab == 0 ? _myEvents : _joinedEvents;
        return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                        children: [
                            Expanded(
                                child: _eventsSubTabButton(0, 'Oluşturduklarım', _myEvents.length),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                                child: _eventsSubTabButton(1, 'Katıldıklarım', _joinedEvents.length),
                            ),
                        ],
                    ),
                    const SizedBox(height: 12),
                    if (activeList.isEmpty)
                        Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                                child: Text(
                                    _eventsSubTab == 0
                                        ? 'Henüz bir etkinlik oluşturmadın.'
                                        : 'Henüz bir etkinliğe katılmadın.',
                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                            ),
                        )
                    else
                        ...activeList.map((e) => _eventListCard(e)),
                ],
            ),
        );
    }

    // Etkinlikler sekmesi içindeki Oluşturduklarım/Katıldıklarım seçim butonu
    Widget _eventsSubTabButton(int index, String label, int count) {
        final selected = _eventsSubTab == index;
        return GestureDetector(
            onTap: () => setState(() => _eventsSubTab = index),
            child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                    color: selected ? const Color(0xFF1A237E) : const Color(0xFF1A237E).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                    '$label ($count)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : const Color(0xFF1A237E),
                    ),
                ),
            ),
        );
    }

    // tek bir etkinlik satırı - hem Oluşturduklarım hem Katıldıklarım listesinde kullanılıyor
    Widget _eventListCard(Map<String, dynamic> e) {
        final pending = e['pendingRequestCount'] ?? 0;
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
                trailing: pending > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                            '$pending istek',
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                    )
                    : const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EventDetailPage(eventId: e['id'])),
                    );
                },
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
                    Row(
                        children: [
                            const Text(
                                'Değerlendirmeler',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                            ),
                            if (ratingCount > 0) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(
                                    '${_ratings!['averageScore']} ($ratingCount)',
                                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                            ],
                        ],
                    ),
                    const SizedBox(height: 12),
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
                                    'Henüz değerlendirme almadın.',
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
}
