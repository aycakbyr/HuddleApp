// Navigator.push → yeni ekrana git (geri dönülebilir)
// Navigator.pop → bir önceki ekrana dön

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import '../utils/snackbar_helper.dart';

class RegisterPage extends StatefulWidget {
    const RegisterPage({super.key});

    @override
    State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
    final _authService = AuthService();
    bool _isLoading = false;
    final _nameController = TextEditingController(); //okuyucular
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    String? _nameError; //hata mesajları , ? null olabilir diye
    String? _emailError;
    String? _passwordError;
    String _selectedGender = '';
    DateTime? _birthDate;
    String? _birthDateError;

    @override
    void dispose(){
        _nameController.dispose(); //kullanıcı bu ekrandan çıkınca controllerlar bellekten temizlensin
        _emailController.dispose();
        _passwordController.dispose();
        super.dispose();
    }

    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: const Color(0xFFFAF7F2),
            body: SafeArea(
                child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SingleChildScrollView(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Text(
                                'Huddle',
                                style: GoogleFonts.pacifico(
                                    fontSize: 42,
                                    color: Color(0xFF1A237E),
                                    fontWeight: FontWeight.bold,
                                ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                                'Hesap oluştur',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                ),
                            ),
                            const SizedBox(height: 40),
                            TextField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                    labelText: 'Ad Soyad',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person),
                                    errorText: _nameError,
                                ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                    labelText: 'E-posta',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.email),
                                    errorText: _emailError,
                                ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                    labelText: 'Şifre',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.lock),
                                    errorText: _passwordError,
                                ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                                'Cinsiyet',
                                style: TextStyle(
                                    fontSize: 14, 
                                    color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Row(
                                children: [
                                    Expanded(
                                        child: GestureDetector( //dokunma olayı ekler, ontap basınca çalışır
                                            onTap: () => setState(() => _selectedGender = 'male'),
                                            child: Container(    // renk kenarlık gibi görsel özellik
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                decoration: BoxDecoration(    // container ın görünümünü özelleştirmek için 
                                                    border: Border.all(
                                                        color: _selectedGender == 'male'
                                                           ? Color(0xFF1A237E)
                                                           : Colors.grey, 
                                                    ),
                                                    borderRadius: BorderRadius.circular(8),
                                                    color: _selectedGender == 'male'
                                                           ? Color(0xFF1A237E).withOpacity(0.1)
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
                                                        color: _selectedGender == 'female'
                                                            ? Color(0xFF1a237E)
                                                            : Colors.grey,
                                                    ),
                                                    borderRadius: BorderRadius.circular(8),
                                                    color: _selectedGender == 'female'
                                                            ? Color(0xFF1A237E).withOpacity(0.1)
                                                            : Colors.transparent,
                                                ),
                                                child: const Center(child: Text('Kadın')),
                                            ),
                                        ),
                                    ),
                                ],
                            ),
                                  const SizedBox(height: 16),
                            const Text(
                                'Doğum Tarihi',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                                onTap: () async {
                                    final picked = await showDatePicker( // hazır takvim seçici, async await de seç butonuna basana kadar bekle
                                        context: context,
                                        initialDate: DateTime(2000),
                                        firstDate: DateTime(1900),
                                        lastDate: DateTime.now(),
                                    );
                                    if(picked != null) {
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
                                        border: Border.all(
                                            color: _birthDateError != null ? Colors.red : Colors.grey,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                        children: [
                                            const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                                            const SizedBox(width: 12),
                                            Text(
                                                _birthDate == null
                                                    ? 'Doğum Tarihi seçin'
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
                            if(_birthDateError != null)
                                Padding(
                                    padding: const EdgeInsets.only(top: 4, left: 12),
                                    child: Text(
                                        _birthDateError!,
                                        style: const TextStyle(color: Colors.red, fontSize: 12),
                                    ),
                                ),
                            const SizedBox(height: 24),
                            SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                    onPressed: _isLoading ? null : () async {
                                        final name = _nameController.text.trim();
                                        final email = _emailController.text.trim();
                                        final password = _passwordController.text;

                                        //yaş hesaplama
                                        int age = 0;
                                        if(_birthDate != null) {
                                            final today = DateTime.now();
                                            age = today.year - _birthDate!.year;
                                            if(today.month < _birthDate!.month || (today.month == _birthDate!.month && today.day < _birthDate!.day)) {
                                            age--;    
                                            }
                                        }

                                        setState((){
                                            _nameError = name.isEmpty ? 'Ad Soyad boş bırakılamaz!' : null;
                                            _emailError = email.isEmpty ? 'Email boş bırakılamaz!' : null;
                                            _passwordError = password.isEmpty ? 'Şifre boş bırakılamaz!' : password.length < 6 
                                                ? 'Şifre en az 6 karakter olmalı!'
                                                : null;
                                            _birthDateError = _birthDate == null
                                                ? 'Doğum tarihi seçilmeli'
                                                : age < 18
                                                      ? '18 yaşından küçükler kayıt olamaz'
                                                      : null;
                                        });

                                        if(_nameError != null || _emailError != null || _passwordError != null ||
                                        _birthDateError != null) return;

                                        final genderValue = _selectedGender == 'male'
                                              ? 1
                                              : _selectedGender == 'female'
                                                    ? 2
                                                    : 0;
                                        
                                        setState(() => _isLoading = true);

                                        final result = await _authService.register(
                                            email : email,
                                            password : password,
                                            displayName : name,
                                            gender : genderValue,
                                            birthDate : _birthDate!,
                                        );

                                        if (!mounted) return;

                                        setState(() => _isLoading = false);

                                        if (result['success'] == true){
                                            Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(builder: (contex) => const HomePage()),
                                            );
                                        } else {
                                            showAppSnackBar(
                                                    context, result['message'],
                                                    color: Colors.red);
                                        }

                                    },
                                    child: _isLoading
                                        ? const CircularProgressIndicator()
                                        : const Text('Kayıt Ol'),
                                ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    const Text('Zaten hesabın var mı?'),
                                    TextButton(
                                        onPressed: () {
                                            Navigator.pop(context); // geri dön
                                        },
                                        child: const Text('Giriş yap'),
                                    ),
                                ],
                            ),
                        ],
                    ),
                    ),
                ),
            ),
        );
    }
}