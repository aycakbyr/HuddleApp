import 'package:flutter/material.dart';
import 'event_detail_page.dart';
import '../services/event_service.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String _selectedCategory = 'Tümü';
  String _selectedSort = 'En Yakın';

  final _eventService = EventService();
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _categories = [
    'Tümü', 'Spor', 'Kitap', 'Oyun', 'Müzik', 'Yemek', 'Diğer'
  ];

  final List<Color> _cardColors = [
    Color(0xFFFFF3E0), // turuncu
    Color(0XFFE8F5E9), // yeşil
    Color(0XFFE3F2FD), // mavi
    Color(0XFFFCE4EC), // pembe
    Color(0xFFF3E5F5), // mor
    Color(0xFFFFF9C4), // sarı
  ];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  // backend'den gelen ham veriyi ekranın beklediği alan isimlerine çevirir
  Map<String, dynamic> _mapEvent(Map<String, dynamic> e) {
    final genderMap = {'All': 'Tümü', 'Male': 'Erkeklere özel', 'Female': 'Kadınlara özel'};
    final startTime = DateTime.parse(e['startTime']).toLocal();

    return {
      'id': e['id'],
      'title': e['title'],
      'category': e['categoryName'],
      'distance': '-', // konum hesaplaması henüz yok
      'time': '${startTime.day}/${startTime.month} ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      'participants': e['participantCount'],
      'gender': genderMap[e['targetGender']] ?? 'Tümü',
      'address': e['address'],
      'organizer': e['organizerName'],
      'imageUrl': e['imageUrl'],
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

  Widget _sortChip(String label) {
    final isSelected = _selectedSort == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedSort = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1A237E).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A237E) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1A237E) : Colors.grey,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Kategori filtreleri
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1A237E)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1A237E)),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF1A237E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Sıralama
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'Sırala:',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _sortChip('En Yakın'),
                      _sortChip('En Yeni'),
                      _sortChip('En Popüler'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Etkinlik listesi
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : _events.isEmpty
                      ? const Center(child: Text('Henüz etkinlik yok.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _events.length,
                          itemBuilder: (context, index) {
                            final event = _events[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: _cardColors[index % _cardColors.length],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (event['imageUrl'] != null) ...[
                                        ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.network(
                                                event['imageUrl'],
                                                height: 140,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                            ),
                                        ),
                                        const SizedBox(height: 12),
                                    ],
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            event['title'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1A237E),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1A237E).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            event['category'],
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF1A237E),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(event['time'],
                                            style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.people, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text('${event['participants']}',
                                            style: const TextStyle(color: Colors.grey, fontSize: 13)),

                                    const Spacer(),
                                        TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EventDetailPage(eventId: event['id']),
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          backgroundColor: const Color(0xFF1A237E),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('İncele', style: TextStyle(fontSize: 13)),
                                            SizedBox(width: 4),
                                            Icon(Icons.arrow_forward, size: 14),
                                          ],
                                        ),
                                      ),
                                      ],
                                    ),
                                    if(event['gender'] != 'Tümü')
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.pink.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            event['gender'],
                                            style: const TextStyle(fontSize: 11, color: Colors.pink),
                                        ),
                                      ),
                                    ),
                                  ],
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