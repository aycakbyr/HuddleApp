import 'package:flutter/material.dart';
import '../services/community_service.dart';
import '../utils/snackbar_helper.dart';

class CreateCommunityPage extends StatefulWidget {
    const CreateCommunityPage({super.key});

    @override 
    State<CreateCommunityPage> createState() => _CreateCommunityPageState();
}

class _CreateCommunityPageState extends State<CreateCommunityPage> {
    final _communityService = CommunityService();
    final _nameController = TextEditingController();
    final _descriptionController = TextEditingController();

    bool _isSubmitting = false;
    String? _nameError;

    @override
    void dispose() {
        _nameController.dispose();
        _descriptionController.dispose();
        super.dispose();
    }
    
    Future<void> _submit() async {
        final name = _nameController.text.trim();
        final description = _descriptionController.text.trim();

        setState(() {
            _nameError = name.isEmpty ? 'Topluluk adı boş bırakılamaz!' : null ;
        });

        if (_nameError != null) return;

        setState(() => _isSubmitting = true);

        final result = await _communityService.createCommunity(
            name: name,
            description: description,
        );

        if (!mounted) return;

        if (result['success'] != true) {
            setState(() => _isSubmitting = false);
            showAppSnackBar(context, result['message'], color: Colors.red);
            return;
        }

        setState(() => _isSubmitting = false);
        showAppSnackBar(context, 'Topluluk oluşturuldu!', color: Colors.green);

        Navigator.pop(context, true);
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: const Color(0xFFFAF7F2),
            appBar: AppBar(
                backgroundColor: const Color(0xFFFAF7F2),
                elevation: 0,
                title: const Text(
                    'Topluluk Oluştur',
                    style: TextStyle(color: Color(0xFF1A237E)),
                ),
                iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
            ),
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                                labelText: 'Topluluk Adı',
                                border: const OutlineInputBorder(),
                                errorText: _nameError,
                            ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                            controller: _descriptionController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                                labelText: 'Açıklama',
                                border: OutlineInputBorder(),
                            ),
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
                                    : const Text('Topluluğu Oluştur'),
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}