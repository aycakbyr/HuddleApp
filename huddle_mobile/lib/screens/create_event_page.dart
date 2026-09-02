import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import '../services/event_service.dart';
import '../utils/snackbar_helper.dart';


class CreateEventPage extends StatefulWidget {
    final String? eventIdToEdit; // doluysa sayfa düzenleme modunda açılır

    const CreateEventPage({super.key, this.eventIdToEdit});

    @override
    State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
    final _eventService = EventService();
    final _titleController = TextEditingController();
    final _descriptionController = TextEditingController();
    final _addressController = TextEditingController();
    final _picker = ImagePicker();

    List<Map<String, dynamic>> _categories = [];
    String? _selectedCategoryId;
    bool _loadingCategories = true;

    String _selectedTargetGender = 'all'; // 'all' | 'male' | 'female'
    DateTime? _startTime;
    LatLng? _selectedLocation;
    final _locationSearchController = TextEditingController();
    List<Map<String, dynamic>> _searchResults = [];
    bool _isSearching = false;
    final _mapController = MapController();
    File? _selectedImage;

    bool _isSubmitting = false;
    String? _titleError;
    String? _addressError;
    String? _categoryError;
    String? _dateError;
    String? _locationError;

    @override
    void initState() {
        super.initState();
        _loadCategories();
        if (widget.eventIdToEdit != null){
            _loadEventToEdit();
        }
    }

    //düzenleme modunda mevcut bilgileri çeker 
    Future<void> _loadEventToEdit() async {
        final raw = await _eventService.getEventById(widget.eventIdToEdit!);
        if (!mounted) return;
        setState(() {
            _titleController.text = raw['title'] ?? '';
            _descriptionController.text = raw['description'] ?? '';
            _addressController.text = raw['address'] ?? '';
            _selectedCategoryId = raw['categoryId'] ?? '';
            _selectedLocation = LatLng(raw['latitude'], raw['longitude']);
            _startTime = DateTime.parse(raw['startTime']).toLocal();
            _selectedTargetGender = raw['targetGender'] == 'Male'
                ? 'male'
                : raw['targetGender'] == 'Female'
                    ? 'female'
                    : 'all';
        });
    }
    Future<void> _loadCategories() async {
        final categories = await _eventService.getCategories();
        if (!mounted) return;
        setState(() {
            _categories = categories;
            _loadingCategories = false;
        });
    }

    @override
    void dispose() {
        _titleController.dispose();
        _descriptionController.dispose();
        _addressController.dispose();
        _locationSearchController.dispose();
        super.dispose();
    }

    Future<void> _pickImage() async {
        final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (picked != null) {
            setState(() => _selectedImage = File(picked.path));
        }
    }

    Future<void> _pickDateTime() async {
        final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now().add(const Duration(days: 1)),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date == null || !mounted) return;

        final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
        );
        if (time == null) return;

        setState(() {
            _startTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
            _dateError = null;
        });
    }

    Future<void> _submit() async {
        final title = _titleController.text.trim();
        final description = _descriptionController.text.trim();
        final address = _addressController.text.trim();

        setState(() {
            _titleError = title.isEmpty ? 'Başlık boş bırakılamaz!' : null;
            _addressError = address.isEmpty ? 'Adres boş bırakılamaz!' : null;
            _categoryError = _selectedCategoryId == null ? 'Kategori seçmelisin' : null;
            _dateError = _startTime == null ? 'Tarih ve saat seçmelisin' : null;
            _locationError = _selectedLocation == null ? 'Haritadan bir konum seç' : null;
        });

        if (_titleError != null || _addressError != null || _categoryError != null ||
            _dateError != null || _locationError != null) return;

        setState(() => _isSubmitting = true);

        final genderValue = _selectedTargetGender == 'male'
            ? 1
            : _selectedTargetGender == 'female'
                ? 2
                : 0;

        final result = widget.eventIdToEdit == null
            ? await _eventService.createEvent(
            categoryId: _selectedCategoryId!,
            title: title,
            description: description,
            address: address,
            latitude: _selectedLocation!.latitude,
            longitude: _selectedLocation!.longitude,
            targetGender: genderValue,
            startTime: _startTime!,
            )
            : await _eventService.updateEvent(
                eventId: widget.eventIdToEdit!,
                categoryId: _selectedCategoryId!,
                title: title,
                description: description,
                address: address,
                latitude: _selectedLocation!.latitude,
                longitude: _selectedLocation!.longitude,
                targetGender: genderValue,
                startTime: _startTime!,
            );

        if (!mounted) return;

        if (result['success'] != true) {
            setState(() => _isSubmitting = false);
            showAppSnackBar(context, result['message'], color: Colors.red);
            return;
        }

        if (_selectedImage != null) {
            final eventId = result['data']['id'];
            await _eventService.uploadEventImage(eventId, _selectedImage!);
        }

        if (!mounted) return;
        setState(() => _isSubmitting = false);

            showAppSnackBar(context, widget.eventIdToEdit == null ? 'Etkinlik oluşturuldu!' : 'Etkinlik güncellendi!', color: Colors.green);

        Navigator.pop(context, true);
    }

    Widget _genderChip(String value, String label) {
        final isSelected = _selectedTargetGender == value;
        return Expanded(
            child: GestureDetector(
                onTap: () => setState(() => _selectedTargetGender = value),
                child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: isSelected ? const Color(0xFF1A237E) : Colors.grey,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected
                            ? const Color(0xFF1A237E).withOpacity(0.1)
                            : Colors.transparent,
                    ),
                    child: Center(child: Text(label)),
                ),
            ),
        );
    }

    //nomination ücretsiz osm arama servisi için adres ve yer adı
    Future<void> _searchLocation(String query) async {
        if (query.trim().isEmpty) return;
        setState(() => _isSearching = true);
        try{
            final dio = Dio();
            final response = await dio.get('https://nominatim.openstreetmap.org/search',
            queryParameters: {
                'q': query,
                'format': 'json',
                'limit': 5,
                'countrycodes': 'tr',
            },
            options: Options(headers: {'User-Agent': 'HuddleApp/1.0'}),
            );
            final results = List<Map<String, dynamic>>.from(response.data);
            if (!mounted) return;
            setState(() {
            _searchResults = results;
            _isSearching = false;
            });
        } catch (e) {
        if (!mounted) return;
        setState(() {
        _searchResults = [];
        _isSearching = false;
        });
        }
    }
     // arama sonuçlarından birini seçince haritayı oraya taşır ve pin koyar
    void _selectSearchResult(Map<String, dynamic> result) {
        final lat = double.parse(result['lat']);
        final lon = double.parse(result['lon']);
        final point = LatLng(lat, lon);
        setState(() {
            _selectedLocation = point;
            _locationError = null;
            _searchResults = [];
            _locationSearchController.text = result['display_name'] ?? '';
            if (_addressController.text.trim().isEmpty) {
                _addressController.text = result['display_name'] ?? '';
            }
        });
        _mapController.move(point, 15);
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: const Color(0xFFFAF7F2),
            appBar: AppBar(
                backgroundColor: const Color(0xFFFAF7F2),
                elevation: 0,
                title: Text(
                    widget.eventIdToEdit == null ? 'Etkinlik Oluştur' : 'Etkinliği Düzenle',
                    style: const TextStyle(color: Color(0xFF1A237E)),
                ),
                iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
            ),
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        // resim seçici
                        GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                                height: 160,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                    image: _selectedImage != null
                                        ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                                        : null,
                                ),
                                child: _selectedImage == null
                                    ? const Center(
                                        child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                                Icon(Icons.add_a_photo, color: Colors.grey, size: 32),
                                                SizedBox(height: 8),
                                                Text('Fotoğraf ekle', style: TextStyle(color: Colors.grey)),
                                            ],
                                        ),
                                    )
                                    : null,
                            ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                            controller: _titleController,
                            decoration: InputDecoration(
                                labelText: 'Başlık',
                                border: const OutlineInputBorder(),
                                errorText: _titleError,
                            ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                                labelText: 'Açıklama',
                                border: OutlineInputBorder(),
                            ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                            controller: _addressController,
                            decoration: InputDecoration(
                                labelText: 'Adres',
                                border: const OutlineInputBorder(),
                                errorText: _addressError,
                            ),
                        ),
                        const SizedBox(height: 16),

                        const Text('Kategori', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 8),
                        _loadingCategories
                            ? const Center(child: CircularProgressIndicator())
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _categories.map((cat) {
                                    final isSelected = _selectedCategoryId == cat['id'];
                                    return GestureDetector(
                                        onTap: () => setState(() => _selectedCategoryId = cat['id']),
                                        child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            decoration: BoxDecoration(
                                                color: isSelected ? const Color(0xFF1A237E) : Colors.white,
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: const Color(0xFF1A237E)),
                                            ),
                                            child: Text(
                                                cat['name'],
                                                style: TextStyle(
                                                    color: isSelected ? Colors.white : const Color(0xFF1A237E),
                                                ),
                                            ),
                                        ),
                                    );
                                }).toList(),
                            ),
                        if (_categoryError != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(_categoryError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                            ),
                        const SizedBox(height: 16),

                        const Text('Kime açık', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 8),
                        Row(
                            children: [
                                _genderChip('all', 'Tümü'),
                                _genderChip('male', 'Erkek'),
                                _genderChip('female', 'Kadın'),
                            ],
                        ),
                        const SizedBox(height: 16),

                        GestureDetector(
                            onTap: _pickDateTime,
                            child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                decoration: BoxDecoration(
                                    border: Border.all(color: _dateError != null ? Colors.red : Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                    children: [
                                        const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                                        const SizedBox(width: 12),
                                        Text(
                                            _startTime == null
                                                ? 'Tarih ve saat seçin'
                                                : '${_startTime!.day}/${_startTime!.month}/${_startTime!.year}  ${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
                                        ),
                                    ],
                                ),
                            ),
                        ),
                        const SizedBox(height: 16),

                        const Text('Konum (haritaya dokunarak seç)', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextField(
                            controller: _locationSearchController,
                            decoration: InputDecoration(
                                labelText: 'Konum ara',
                                border: const OutlineInputBorder(),
                                suffixIcon: _isSearching
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(
                                            width: 16, height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                    ) 
                                    : IconButton(
                                        icon: const Icon(Icons.search),
                                        onPressed: () => _searchLocation(_locationSearchController.text),
                                    ),
                            ),
                            onSubmitted: _searchLocation,
                        ),
                        if (_searchResults.isNotEmpty)
                        Container(
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                            ),
                            constraints: const BoxConstraints(maxHeight: 180),
                            child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                    final result = _searchResults[index];
                                    return ListTile(
                                        dense: true,
                                        leading: const Icon(Icons.place, size: 18, color: Color(0xFF1A237E)),
                                        title: Text(
                                            result['display_name'] ?? '',
                                            style: const TextStyle(fontSize: 13),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                        ),
                                        onTap: () => _selectSearchResult(result),
                                    );
                                },
                            ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                            height: 220,
                            decoration: BoxDecoration(
                                border: Border.all(color: _locationError != null ? Colors.red : Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                    initialCenter: const LatLng(36.8969, 30.7133), // Antalya
                                    initialZoom: 12,
                                    onTap: (tapPosition, point) {
                                        setState(() {
                                            _selectedLocation = point;
                                            _locationError = null;
                                        });
                                    },
                                ),
                                children: [
                                    TileLayer(
                                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.huddle.huddle_mobile',
                                    ),
                                    if (_selectedLocation != null)
                                        MarkerLayer(
                                            markers: [
                                                Marker(
                                                    point: _selectedLocation!,
                                                    width: 40,
                                                    height: 40,
                                                    child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                                                ),
                                            ],
                                        ),
                                ],
                            ),
                        ),
                        if (_locationError != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(_locationError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                            ),
                        const SizedBox(height: 24),

                        SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    backgroundColor: const Color(0xFF1A237E),
                                    foregroundColor: Colors.white,
                                ),
                                child: _isSubmitting
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(widget.eventIdToEdit == null ? 'Etkinliği Oluştur' : 'Değişiklikleri Kaydet'),
                            ),
                        ),
                        const SizedBox(height: 24),
                    ],
                ),
            ),
        );
    }
}