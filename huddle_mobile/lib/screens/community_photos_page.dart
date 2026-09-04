import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/community_service.dart';
import '../utils/snackbar_helper.dart';

class CommunityPhotosPage extends StatefulWidget {
    final String communityId;

    const CommunityPhotosPage({super.key, required this.communityId});

    @override
    State<CommunityPhotosPage> createState() => _CommunityPhotosPageState();
}

class _CommunityPhotosPageState extends State<CommunityPhotosPage> {
    final _communityService = CommunityService();
    final _picker = ImagePicker();
    List<Map<String, dynamic>> _photos = [];
    bool _isLoading = true;
    bool _isUploadingPhoto = false;

    @override
    void initState() {
        super.initState();
        _loadPhotos();
    }

    Future<void> _loadPhotos() async {
        setState(() => _isLoading = true);
        try {
            final photos = await _communityService.getCommunityPhotos(widget.communityId);
            if (!mounted) return;
            setState(() {
                _photos = photos;
                _isLoading = false;
            });
        } catch (e) {
            if (!mounted) return;
            setState(() => _isLoading = false);
        }
    }

    Future<void> _pickAndUploadPhoto() async {
        final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (picked == null) return;

        setState(() => _isUploadingPhoto = true);
        final result = await _communityService.uploadCommunityPhoto(widget.communityId, File(picked.path));
        if (!mounted) return;
        setState(() => _isUploadingPhoto = false);

        if (result['success'] == true) {
            _loadPhotos();
        } else {
            showAppSnackBar(context, result['message'], color: Colors.red);
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: const Color(0xFFFAF7F2),
            appBar: AppBar(
                backgroundColor: const Color(0xFFFAF7F2),
                elevation: 0,
                title: const Text('Fotoğraflar', style: TextStyle(color: Color(0xFF1A237E))),
                iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
                actions: [
                    IconButton(
                        onPressed: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                        icon: _isUploadingPhoto
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.add_a_photo_outlined),
                        tooltip: 'Fotoğraf Ekle',
                    ),
                ],
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _photos.isEmpty
                    ? const Center(
                        child: Text('Henüz fotoğraf yok.', style: TextStyle(color: Colors.grey)),
                    )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                        ),
                        itemCount: _photos.length,
                        itemBuilder: (context, i) {
                            final photo = _photos[i];
                            return ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                    photo['imageUrl'],
                                    fit: BoxFit.cover,
                                ),
                            );
                        },
                    ),
        );
    }
}
