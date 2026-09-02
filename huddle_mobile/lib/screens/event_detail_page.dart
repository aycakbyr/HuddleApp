import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/event_service.dart';
import '../services/auth_service.dart';
import 'create_event_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'user_profile_page.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/snackbar_helper.dart';

class EventDetailPage extends StatefulWidget {
    final String eventId;
    const EventDetailPage({super.key, required this.eventId});

    @override
    State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage>{
    final _eventService = EventService();
    final _picker = ImagePicker();
    bool _hasRequested = false;
    bool _isJoining = false;
    Map<String, dynamic>? _event;
    bool _isLoading = true;
    String? _errorMessage;
    List<Map<String, dynamic>> _photos = [];
    bool _isUploadingPhoto = false;
    bool _isRating = false;
    String? _myUserId;

    final List<Color> _avatarColors = [
        Color(0xFFFFEB2),
        Color(0xFFC8E6C9),
        Color(0xFFBBDEFB),
        Color(0xFFF8BBD0),
        Color(0xFFE1BEE7),
    ];

    @override
    void initState() {
        super.initState();
        _loadEvent();
        _loadMyUserId();
    }

    //düzenle butonunu sadece etkinliği oluşturan görsün
    Future<void> _loadMyUserId() async {
        final me = await AuthService().getMe();
        if (!mounted || me == null) return;
        setState(() => _myUserId = me['id']?.toString());
    }

    // backend'in EventDetailDto'sunu ekranın beklediği alan isimlerine çevirir
    Map<String, dynamic> _mapDetail(Map<String, dynamic> e) {
        final genderMap = {'All': 'Tümü', 'Male': 'Erkeklere özel', 'Female': 'Kadınlara özel'};
        final startTime = DateTime.parse(e['startTime']).toLocal();
        final participants = List<Map<String, dynamic>>.from(e['participants'] ?? []);

        return {
            'title': e['title'],
            'category': e['categoryName'],
            'organizer': e['organizerName'],
            'organizerId': e['organizerId'],
            'time': '${startTime.day}/${startTime.month}/${startTime.year} ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
            'distance': '-',
            'participants': participants.length,
            'gender': genderMap[e['targetGender']] ?? 'Tümü',
            'description': e['description'],
            'address': e['address'],
            'imageUrl': e['imageUrl'],
            'latitude': e['latitude'],
            'longitude': e['longitude'],
            'currentUserStatus': e['currentUserStatus'],
            'participantList': participants.map((p) => {'userId': p['userId'], 'displayName': p['displayName']}).toList(),
            'canAddMemoryPhoto': e['canAddMemoryPhoto'] == true,
            'canRateOrganizer': e['canRateOrganizer'] == true,
            'myRatingScore': e['myRatingScore'],
            'myRatingComment': e['myRatingComment'],
            'organizerAverageRating': e['organizerAverageRating'],
            'organizerRatingCount': e['organizerRatingCount'] ?? 0,
            'eventRatings': List<Map<String, dynamic>>.from(e['eventRatings'] ?? []),
        };
    }

    Future<void> _loadEvent() async {
        try {
            final raw = await _eventService.getEventById(widget.eventId);
            if (!mounted) return;
            final mapped = _mapDetail(raw);
            setState(() {
                _event = mapped;
                _hasRequested = mapped['currentUserStatus'] == 'Pending' || mapped['currentUserStatus'] == 'Approved';
                _isLoading = false;
            });
            _loadPhotos();
        } catch (e) {
            if (!mounted) return;
            setState(() {
                _errorMessage = 'Etkinlik yüklenemedi.';
                _isLoading = false;
            });
        }
    }

    Future<void> _loadPhotos() async {
        try {
            final photos = await _eventService.getEventPhotos(widget.eventId);
            if (!mounted) return;
            setState(() => _photos = photos);
        } catch (e) {
            // sessizce geç, anı fotoğrafları olmadan da sayfa çalışsın
        }
    }

    Future<void> _pickAndUploadPhoto() async {
        final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (picked == null) return;

        setState(() => _isUploadingPhoto = true);
        final result = await _eventService.uploadEventMemoryPhoto(widget.eventId, File(picked.path));
        if (!mounted) return;
        setState(() => _isUploadingPhoto = false);

        if (result['success'] == true) {
            _loadPhotos();
        } else {
            showAppSnackBar(context, result['message'], color: Colors.red);
        }
    }

    Future<void> _showRateDialog() async {
    final event = _event!;
    int selectedScore = (event['myRatingScore'] ?? 5) as int;
    int selectedCommunication = (event['myRatingCommunicationScore'] ?? 5) as int;
    int selectedOrganization = (event['myRatingOrganizationScore'] ?? 5) as int;
    int selectedWarmth = (event['myRatingWarmthScore'] ?? 5) as int;
    final commentController = TextEditingController(text: event['myRatingComment'] ?? '');

    Widget starRow(int value, ValueChanged<int> onChanged, {double size = 28}) {
        return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
                final starIndex = i + 1;
                return IconButton(
                    onPressed: () => onChanged(starIndex),
                    icon: Icon(
                        starIndex <= value ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: size,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                );
            }),
        );
    }

    Widget categoryRow(String label, int value, ValueChanged<int> onChanged) {
        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    Expanded(
                    child: Text(label, style: const TextStyle(fontSize: 14)),
                    ),
                    starRow(value, onChanged, size: 20),
                ],
            ),
        );
    }

    final submitted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
            return StatefulBuilder(
                builder: (dialogContext, setDialogState) {
                    return AlertDialog(
                        title: const Text('Kurucuyu Değerlendir'),
                        content: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    starRow(
                                        selectedScore,
                                        (v) => setDialogState(() => selectedScore = v),
                                        size: 34,
                                    ),
                                    const SizedBox(height: 8),
                                    const Divider(),
                                    categoryRow(
                                        'İletişim',
                                        selectedCommunication,
                                        (v) => setDialogState(() => selectedCommunication = v),
                                    ),
                                    categoryRow(
                                        'Organizasyon',
                                        selectedOrganization,
                                        (v) => setDialogState(() => selectedOrganization = v),
                                    ),
                                    categoryRow(
                                        'Samimiyet',
                                        selectedWarmth,
                                        (v) => setDialogState(() => selectedWarmth = v),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                        controller: commentController,
                                        maxLines: 3,
                                        decoration: const InputDecoration(
                                            hintText: 'Deneyimini paylaş (isteğe bağlı)',
                                            border: OutlineInputBorder(),
                                        ),
                                    ),
                                ],
                            ),
                        ),
                        actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(dialogContext, false),
                                child: const Text('Vazgeç'),
                            ),
                            ElevatedButton(
                                onPressed: () => Navigator.pop(dialogContext, true),
                                child: const Text('Gönder'),
                            ),
                        ],
                    );
                },
            );
        },
    );

    if (submitted != true) return;

    setState(() => _isRating = true);
    final result = await _eventService.rateEvent(
        widget.eventId,
        selectedScore,
        selectedCommunication,
        selectedOrganization,
        selectedWarmth,
        commentController.text.trim().isEmpty ? null : commentController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isRating = false);

    if (result['success'] == true) {
        showAppSnackBar(context, 'Değerlendirmen kaydedildi.', color: Colors.green);
    
        _loadEvent();
    } else {
        showAppSnackBar(context, result['message'], color: Colors.red);
    }
}

    Future<void> _sendJoinRequest() async {
        setState(() => _isJoining = true);

        final result = _hasRequested
            ? await _eventService.cancelJoinRequest(widget.eventId)
            : await _eventService.joinEvent(widget.eventId);

        if (!mounted) return;
        setState(() => _isJoining = false);

        if (result['success'] == true) {
            setState(() => _hasRequested = !_hasRequested);
        } else {
            showAppSnackBar(context, result['message'], color: Colors.red);
        }
    }

    Widget _infoRow(IconData icon, String label, String value) {
        return Row(
            children: [
                Icon(icon, size: 20, color: const Color(0xFF1A237E)),
                const SizedBox(width: 12),
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const Spacer(),
                Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
            ],
        );
    }

    // google map konumuna yönelndirir
    Future<void> _openDirections(double lat, double lng) async {
        final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
        final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
        if (!opened && mounted) {
            showAppSnackBar(context, 'Harita uygulaması açılamadı');
        }
    }

    @override
    Widget build(BuildContext context) {
        if (_isLoading) {
            return const Scaffold(
                backgroundColor: Color(0xFFFAF7F2),
                body: Center(child: CircularProgressIndicator()),
            );
        }

        if (_errorMessage != null || _event == null) {
            return Scaffold(
                backgroundColor: const Color(0xFFFAF7F2),
                appBar: AppBar(backgroundColor: const Color(0xFFFAF7F2), elevation: 0),
                body: Center(child: Text(_errorMessage ?? 'Bir hata oluştu.')),
            );
        }

        final event = _event!;

        return Scaffold(
            backgroundColor: const Color(0xFFFAF7F2),
                        appBar: AppBar(
                backgroundColor: const Color(0xFFFAF7F2),
                elevation: 0,
                iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
                title: const Text(
                    'Etkinlik Detayı',
                    style: TextStyle(color: Color(0xFF1A237E), fontSize: 18),
                ),
                actions: [
                    if (_myUserId != null && _myUserId == event['organizerId'])
                        TextButton(
                            onPressed: () async {
                                final updated = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => CreateEventPage(eventIdToEdit: widget.eventId),
                                    ),
                                );
                                if (updated == true) {
                                    _loadEvent();
                                }
                            },
                            child: const Text(
                                'Düzenle',
                                style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold),
                            ),
                        ),
                ],
            ),
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        if (event['imageUrl'] != null) ...[
                            ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                    event['imageUrl'],
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                ),
                            ),
                            const SizedBox(height: 16),
                        ],
                        Text(
                            event['title'],
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                            ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: const Color(0xFF1A237E).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                                event['category'],
                                style: const TextStyle(fontSize: 13, color: Color(0xFF1A237E)),
                            ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                            onTap: () {
                                final organizerId = event['organizerId'];
                                if (organizerId == null) return;
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => UserProfilePage(userId: organizerId),
                                    ),
                                );
                            },
                            child: Row(
                            children: [
                                CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFF1A237E).withOpacity(0.1),
                                    child: Text(
                                        (event['organizer'] ?? '?')[0],
                                        style: const TextStyle(
                                            color: Color(0xFF1A237E),
                                            fontWeight: FontWeight.bold,
                                        ),
                                    ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        Text(
                                            event['organizer'] ?? 'Bilinmiyor',
                                            style: TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        if ((event['organizerRatingCount'] ?? 0) > 0) ...[
                                            const SizedBox(height: 2),
                                            Row(
                                                children: [
                                                    const Icon(Icons.star, size: 12, color: Colors.amber),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                        '${event['organizerAverageRating']} (${event['organizerRatingCount']})',
                                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                    ),
                                                ],
                                            ),
                                        ],
                                    ],
                                ),
                            ],
                        ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                                children: [
                                    _infoRow(Icons.access_time, 'Tarih&Saat', event['time']),
                                    const Divider(height: 24),
                                    _infoRow(Icons.location_on, 'Mesafe', event['distance']),
                                    const Divider(height: 24),
                                    _infoRow(Icons.people, 'Katılımcı', '${event['participants']} kisi'),
                                    if(event['gender'] != 'Tümü') ...[
                                        const Divider(height: 24),
                                        _infoRow(Icons.wc, 'Katılım', event['gender']),
                                    ],
                                ],
                            ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                            'Açıklama',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                            ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                                (event['description'] == null || (event['description'] as String).isEmpty)
                                    ? 'Açıklama bulunmuyor.'
                                    : event['description'],
                                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                            ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                            'Konum',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                            ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Row(
                                        children: [
                                            const Icon(Icons.place, size: 20, color: Color(0xFF1A237E)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                                child: Text(
                                                    event['address'] ?? 'Adres belirtilmemiş.',
                                                    style: const TextStyle(fontSize: 14),
                                                ),
                                            ),
                                        ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                        height: 150,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: FlutterMap(
                                            options: MapOptions(
                                                initialCenter: LatLng(event['latitude'], event['longitude']),
                                                initialZoom: 14,
                                                interactionOptions: const InteractionOptions(
                                                    flags: InteractiveFlag.none,
                                                ),
                                            ),
                                            children: [
                                                TileLayer(
                                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                                    userAgentPackageName: 'com.huddle.huddle_mobile',
                                                ),
                                                MarkerLayer(
                                                    markers: [
                                                        Marker(
                                                            point: LatLng(event['latitude'], event['longitude']),
                                                            width: 40,
                                                            height: 40,
                                                            child: const Icon(Icons.location_pin, color: Colors.red, size: 36),
                                                        ),
                                                    ],
                                                ),
                                            ],
                                        ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                            onPressed: () => _openDirections(event['latitude'], event['longitude']),
                                            icon: const Icon(Icons.directions, color: Color(0xFF1A237E)),
                                            label: const Text(
                                                'Yol Tarifi Al',
                                                style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.w600),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                                side: const BorderSide(color: Color(0xFF1A237E)),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                        ),
                                    ),
                                ],
                            ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                                onPressed: _isJoining ? null : _sendJoinRequest,
                                style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    backgroundColor: _hasRequested ? Colors.grey : const Color(0xFF1A237E),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                    ),
                                ),
                                child: _isJoining
                                    ? const SizedBox(
                                        height: 18, width: 18,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                    : Text(
                                        _hasRequested ? 'İstek Gönderildi (İptal Et)' : 'Katılım İsteği Gönder',
                                        style: const TextStyle(fontSize: 15),
                                    ),
                            ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                            children: [
                                const Text(
                                    'Katılımcılar',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A237E),
                                    ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF1A237E).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                        '${event['participants']}',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF1A237E)),
                                    ),
                                ),
                            ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                            height: 110,
                            child: (event['participantList'] as List).isEmpty
                                ? const Center(
                                    child: Text('Henüz katılımcı yok', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                )
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: (event['participantList'] as List).length,
                                    itemBuilder: (context, i){
                                        final participant = (event['participantList'] as List)[i];
                                        final name = participant['displayName'] ?? '?';
                                        return GestureDetector(
                                        onTap: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) => UserProfilePage(userId: participant['userId']),
                                                ),
                                            );
                                        },
                                        child: Container(
                                            width: 90,
                                            margin: const EdgeInsets.only(right: 10),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                    CircleAvatar(
                                                        radius: 22,
                                                        backgroundColor: _avatarColors[i % _avatarColors.length],
                                                        child: Text(
                                                            name[0],
                                                            style: const TextStyle(
                                                                color: Color(0xFF1A237E),
                                                                fontWeight: FontWeight.bold,
                                                            ),
                                                        ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                        name,
                                                        style: const TextStyle(fontSize: 11),
                                                        textAlign: TextAlign.center,
                                                        overflow: TextOverflow.ellipsis,
                                                    ),
                                                ],
                                            ),
                                        ));
                                    },
                                ),
                        ),
                        if (event['canAddMemoryPhoto'] == true || _photos.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Row(
                                children: [
                                    const Text(
                                        'Anılar',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1A237E),
                                        ),
                                    ),
                                    const Spacer(),
                                    if (event['canAddMemoryPhoto'] == true)
                                        TextButton.icon(
                                            onPressed: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                                            icon: _isUploadingPhoto
                                                ? const SizedBox(
                                                    height: 14,
                                                    width: 14,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                                : const Icon(Icons.add_a_photo, size: 18),
                                            label: const Text('Fotoğraf Ekle'),
                                        ),
                                ],
                            ),
                            const SizedBox(height: 8),
                            if (_photos.isEmpty)
                                const Text(
                                    'Henüz anı fotoğrafı yok.',
                                    style: TextStyle(color: Colors.grey, fontSize: 13),
                                )
                            else
                                SizedBox(
                                    height: 100,
                                    child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _photos.length,
                                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                                        itemBuilder: (context, i) {
                                            final photo = _photos[i];
                                            return ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.network(
                                                    photo['imageUrl'],
                                                    width: 100,
                                                    height: 100,
                                                    fit: BoxFit.cover,
                                                ),
                                            );
                                        },
                                    ),
                                ),
                        ],
                        if (event['canRateOrganizer'] == true) ...[
                            const SizedBox(height: 24),
                            SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                    onPressed: _isRating ? null : _showRateDialog,
                                    icon: const Icon(Icons.star_border),
                                    label: Text(
                                        event['myRatingScore'] != null
                                            ? 'Değerlendirmeni Güncelle'
                                            : 'Kurucuyu Değerlendir',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        foregroundColor: const Color(0xFF1A237E),
                                        side: const BorderSide(color: Color(0xFF1A237E)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                ),
                            ),
                        ],
                        if ((event['eventRatings'] as List).isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const Text(
                                'Değerlendirmeler',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A237E),
                                ),
                            ),
                            const SizedBox(height: 8),
                            ...List<Map<String, dynamic>>.from(event['eventRatings'])
                                .map((r) => _eventRatingCard(r)),
                        ],
                    ],
                ),
            ),
        );  
    }

    // bir etkinliğe yapılmış tek bir değerlendirmeyi (yorum + puanlar) gösteren kart
    Widget _eventRatingCard(Map<String, dynamic> rating) {
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