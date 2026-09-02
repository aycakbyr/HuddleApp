import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'register_page.dart';
import 'home_page.dart';
import '../services/auth_service.dart';
import '../utils/snackbar_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage ({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage>{
    //controller buraya ekleniyor
    final _authService = AuthService();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    bool _isLoading = false;
    String? _emailError;
    String? _passwordError;

  @override
  void dispose(){ //ekranı kapatınca controller ları da temizler
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: SafeArea(  // içeriği dışarı taşmaktan korur
        child: Padding( //içeriğe her yönden boşluk ekleme
          padding: const EdgeInsets.all(24.0),
          child: Column(   //widgetları dikey sıralar
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,  //column içindeki her şeyi dikey olarak ortalar
            children: [
            Text(
                'Huddle',
                style: GoogleFonts.pacifico(
                  fontSize: 42,
                  color: Color(0xFF1A237E),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'E-posta',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                  errorText: _emailError,  //hata mesajı buraya
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'şifre',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  errorText: _passwordError
                ),
              ),
              const SizedBox(height: 24),
              SizedBox( //butonu ekranın tam genişliğine yay
                width: double.infinity,//mümkün olan en geniş al
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    final email = _emailController.text.trim();
                    final password = _passwordController.text;

                    setState((){
                        _emailError = email.isEmpty ? 'Email boş bırakılamaz!' : null;
                        _passwordError = password.isEmpty
                            ? 'Şifre boş bırakılamaz!'
                            : password.length < 6
                                ? 'Şifre en az 6 karakterli olmalı!'
                                : null;
                    });

                    if(_emailError != null || _passwordError != null) return;

                    setState(() => _isLoading = true );

                    final result = await _authService.login(
                      email: email,
                      password: password,
                    );

                    if (!mounted) return;
                    setState(() => _isLoading = false );

                    if (result['success'] == true ) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                    );
                  } else {
                    showAppSnackBar(context, result['message'],
                        color: Colors.red);
                  }
                  },
                  //butona basınca ne olacak şuan API yok
                  child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Giriş Yap'),
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                    Expanded(child: Divider()), //yatay çizgi , expanded row içinde kalan boşluğu doldurur
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('veya', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                    ),
                    icon: FaIcon(FontAwesomeIcons.google, color: Colors.red, size: 20),
                    label: Text('Google ile devam et'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                    ),
                    icon: Icon(Icons.apple, size: 24),
                    label: Text('Apple ile devam et'),
                ),
              ),
              const SizedBox(height: 16),
              Row( // yatay sıralar,yan yana koyar
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    const Text('Hesabın yok mu?'),
                    TextButton( //düz metin gibi görünen buton
                    onPressed: () {
                      Navigator.pushReplacement( //ekranlar arası geçiş
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterPage()), //yeni ekrana geçerken standart animasyonu kullan
                      );
                    },
                    child: const Text('Kayıt ol'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}