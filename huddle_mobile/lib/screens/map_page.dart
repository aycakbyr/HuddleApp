import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/event_service.dart';
import 'event_detail_page.dart';

class MapPage extends StatefulWidget {
    const MapPage({super.key});

    @override
    State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
    final _eventService = EventService();
    final _searchController = TextEditingController();
    final _mapController = MapController();

    List<Map<String, dynamic>> _events = [];
    bool _isLoading = true;
    String? _errorMessage;

    String _selectedCategory = 'Tümü';
    String _selectedSort = 'En Yeni';
    String _searchQuery = '';

    final List<String> _categories = [
        'Tümü', 'Spor', 'Kitap', 'Oyun', 'Müzik', 'Yemek', 'Diğer'
    ];

    // İstanbul merkezli varsayılan görünüm - hiç etkinlik yoksa ya da konum bilinmiyorsa
    static const LatLng _defaultCenter = LatLng(41.0082, 28.9784);

    @override
    void initState() {
        super.initState();
        _loadEvents();
    }

    @override
    void dispose() {
        _searchController.dispose();
        super.dispose();
    }

    Map<String, dynamic> _mapEvent(Map<String, dynamic> e) {
        return {
            'id': e['id'],
            'title': e['title'],
            'category': e['categoryName'],
            'latitude': e['latitude'],
            'longitude': e['longitude'],
            'participantCount': e['participantCount'] ?? 0,
            'organizerAverageRating': e['organizerAverageRating'],
            'startTime': e['startTime'],
        };
    }

    Future<void> _loadEvents() async {
        setState(() {
            _isLoading = true;
            _errorMessage = null;
        });
        try {
            final rawEvents = await _eventService.getEvents();
            final mapped = rawEvents.map(_mapEvent).toList();
            if (!mounted) return;
            setState(() {
                _events = mapped;
                _isLoading = false;
            });
        } catch (e) {
            if (!mounted) return;
            setState(() {
                _errorMessage = 'Etkinlikler yüklenemedi.';
                _isLoading = false;
            });
        }
    }

    // arama + kategori + sıralamayı uygulayıp haritada gösterilecek listeyi üretir
    List<Map<String, dynamic>> get _filteredEvents {
        var list = _events.where((e) {
            final matchesCategory = _selectedCategory == 'Tümü' || e['category'] == _selectedCategory;
            final matchesSearch = _searchQuery.isEmpty ||
                (e['title'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
            return matchesCategory && matchesSearch;
        }).toList();

        switch (_selectedSort) {
            case 'En Yeni':
                list.sort((a, b) => DateTime.parse(a['startTime']).compareTo(DateTime.parse(b['startTime'])));
                break;
            case 'En Popüler':
                list.sort((a, b) => (b['participantCount'] ?? 0).compareTo(a['participantCount'] ?? 0));
                break;
            case 'En Yüksek Puan':
                list.sort((a, b) {
                    final ra = (a['organizerAverageRating'] ?? 0) as num;
                    final rb = (b['organizerAverageRating'] ?? 0) as num;
                    return rb.compareTo(ra);
                });
                break;
        }
        return list;
    }

    Widget _filterChip(String label, String selected, ValueChanged<String> onTap) {
        final isSelected = selected == label;
        return GestureDetector(
            onTap: () => onTap(label),
            child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1A237E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1A237E)),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
                ),
                child: Text(
                    label,
                    style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF1A237E),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                    ),
                ),
            ),
        );
    }

    // haritada bir etkinliği temsil eden özel işaretçi - kırmızı konum ikonu + üstünde bilgi etiketi
    Widget _eventMarker(Map<String, dynamic> event) {
        final rating = event['organizerAverageRating'];
        return GestureDetector(
            onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EventDetailPage(eventId: event['id'])),
                );
            },
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    Container(
                        constraints: const BoxConstraints(maxWidth: 140),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))],
                        ),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                    event['title'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                        const Icon(Icons.people, size: 11, color: Colors.grey),
                                        const SizedBox(width: 2),
                                        Text('${event['participantCount']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.star, size: 11, color: Colors.amber),
                                        const SizedBox(width: 2),
                                        Text(
                                            rating != null ? '$rating' : '-',
                                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ),
                    const Icon(Icons.location_on, color: Colors.red, size: 34),
                ],
            ),
        );
    }

    @override
    Widget build(BuildContext context) {
        final filtered = _filteredEvents;

        return Scaffold(
            body: Stack(
                children: [
                    // Harita
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                            ? Center(child: Text(_errorMessage!))
                            : FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                    initialCenter: filtered.isNotEmpty
                                        ? LatLng(filtered.first['latitude'], filtered.first['longitude'])
                                        : _defaultCenter,
                                    initialZoom: 11,
                                ),
                                children: [
                                    TileLayer(
                                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.huddle.huddle_mobile',
                                    ),
                                    MarkerLayer(
                                        markers: filtered.map((event) {
                                            return Marker(
                                                point: LatLng(event['latitude'], event['longitude']),
                                                width: 140,
                                                height: 90,
                                                alignment: Alignment.bottomCenter,
                                                child: _eventMarker(event),
                                            );
                                        }).toList(),
                                    ),
                                ],
                            ),

                    // Yakınlaştır / uzaklaştır butonları
                    Positioned(
                        right: 16,
                        bottom: 24,
                        child: Column(
                            children: [
                                FloatingActionButton.small(
                                    heroTag: 'zoom_in',
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF1A237E),
                                    onPressed: () {
                                        _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                                    },
                                    child: const Icon(Icons.add),
                                ),
                                const SizedBox(height: 8),
                                FloatingActionButton.small(
                                    heroTag: 'zoom_out',
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF1A237E),
                                    onPressed: () {
                                        _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                                    },
                                    child: const Icon(Icons.remove),
                                ),
                            ],
                        ),
                    ),

                    // Üstte arama + filtre + sıralama
                    Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SafeArea(
                            child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                    children: [
                                        Container(
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(24),
                                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
                                            ),
                                            child: TextField(
                                                controller: _searchController,
                                                onChanged: (value) => setState(() => _searchQuery = value),
                                                decoration: const InputDecoration(
                                                    hintText: 'Etkinlik ara...',
                                                    prefixIcon: Icon(Icons.search, color: Color(0xFF1A237E)),
                                                    border: InputBorder.none,
                                                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                                                ),
                                            ),
                                        ),
                                        const SizedBox(height: 8),
                                        SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                                children: _categories
                                                    .map((c) => _filterChip(c, _selectedCategory, (v) => setState(() => _selectedCategory = v)))
                                                    .toList(),
                                            ),
                                        ),
                                        const SizedBox(height: 8),
                                        SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                                children: ['En Yeni', 'En Popüler', 'En Yüksek Puan']
                                                    .map((s) => _filterChip(s, _selectedSort, (v) => setState(() => _selectedSort = v)))
                                                    .toList(),
                                            ),
                                        ),
                                    ],
                                ),
                            ),
                        ),
                    ),
                ],
            ),
        );
    }
}
