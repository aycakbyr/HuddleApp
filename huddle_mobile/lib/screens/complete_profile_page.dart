import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/snackbar_helper.dart';
import 'home_page.dart';

// google ile ilk kez giriş yapan kullanıcıdan doğum tarihi + cinsiyet alır (google bunları vermiyor, 18 yaş kontrolü için gerekli)
class CompleteProfilePage extends StatefulWidget {
    const CompleteProfilePage({super.key});

    @override
    State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
    final _authService = AuthService();
    bool _isLoading = false;
    String _selectedGender = '';
    DateTime? _birthDate;
    String? _birthDateError;

    Future<void> _submit() async {
        int age = 0;
        if (_birthDate != null) {
            final today = DateTime.now();
            age = today.year - _birthDate!.year;
            if (today.month < _birthDate!.month || (today.month == _birthDate!.month && today.day < _birthDate!.day)) {
                age--;
            }
        }

        setState(() {
            _birthDateError = _birthDate == null
                ? 'Doğum tarihi seçilmeli'
                : age < 18
                    ? '18 yaşından küçükler devam edemez'
                    : null;
        });

        if (_birthDateError != null) return;

        final genderValue = _selectedGender == 'male'
            ? 1
            : _selectedGender == 'female'
                ? 2
                : 0;

        setState(() => _isLoading = true);

        final result = await _authService.completeProfile(
            gender: genderValue,
            birthDate: _birthDate!,
        );

        if (!mounted) return;
        setState(() => _isLoading = false);

        if (result['success'] == true) {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
            );
        } else {
            showAppSnackBar(context, result['message'], color: Colors.red);
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: const Color(0xFFFAF7F2),
            body: SafeArea(
                child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SingleChildScrollView(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                const SizedBox(height: 16),
                                const Text(
                                    'Profilini Tamamla',
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                    'Google hesabından bu bilgileri alamıyoruz, devam etmeden önce doldurman lazım.',
                                    style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 32),
                                const Text('Cinsiyet', style: TextStyle(fontSize: 14, color: Colors.grey)),
                                const SizedBox(height: 8),
                                Row(
                                    children: [
                                        Expanded(
                                            child: GestureDetector(
                                                onTap: () => setState(() => _selectedGender = 'male'),
                                                child: Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color: _selectedGender == 'male' ? const Color(0xFF1A237E) : Colors.grey,
                                                        ),
                                                        borderRadius: BorderRadius.circular(8),
                                                        color: _selectedGender == 'male'
                                                            ? const Color(0xFF1A237E).withOpacity(0.1)
                                                            : Colors.transparent,
                                                    ),
                                                    child: const Center(child: Text('Erkek')),
                                                ),
                                            ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                            child: GestureDetector(
                                                onTap: () => setState(() => _selectedGender = 'female'),
                                                child: Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color: _selectedGender == 'female' ? const Color(0xFF1A237E) : Colors.grey,
                                                        ),
                                                        borderRadius: BorderRadius.circular(8),
                                                        color: _selectedGender == 'female'
                                                            ? const Color(0xFF1A237E).withOpacity(0.1)
                                                            : Colors.transparent,
                                                    ),
                                                    child: const Center(child: Text('Kadın')),
                                                ),
                                            ),
                                        ),
                                    ],
                                ),
                                const SizedBox(height: 16),
                                const Text('Doğum Tarihi', style: TextStyle(fontSize: 14, color: Colors.grey)),
                                const SizedBox(height: 8),
                                GestureDetector(
                                    onTap: () async {
                                        final picked = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime(2000),
                                            firstDate: DateTime(1900),
                                            lastDate: DateTime.now(),
                                        );
                                        if (picked != null) {
                                            setState(() {
                                                _birthDate = picked;
                                                _birthDateError = null;
                                            });
                                        }
                                    },
                                    child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                        decoration: BoxDecoration(
                                            border: Border.all(color: _birthDateError != null ? Colors.red : Colors.grey),
                                            borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                            children: [
                                                const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                                                const SizedBox(width: 12),
                                                Text(
                                                    _birthDate == null
                                                        ? 'Doğum tarihi seçin'
                                                        : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                                                    style: TextStyle(
                                                        color: _birthDate == null ? Colors.grey : Colors.black87,
                                                        fontSize: 16,
                                                    ),
                                                ),
                                            ],
                                        ),
                                    ),
                                ),
                                if (_birthDateError != null)
                                    Padding(
                                        padding: const EdgeInsets.only(top: 4, left: 12),
                                        child: Text(_birthDateError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                                    ),
                                const SizedBox(height: 32),
                                SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                        onPressed: _isLoading ? null : _submit,
                                        style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            backgroundColor: const Color(0xFF1A237E),
                                            foregroundColor: Colors.white,
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                            : const Text('Devam Et'),
                                    ),
                                ),
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}
