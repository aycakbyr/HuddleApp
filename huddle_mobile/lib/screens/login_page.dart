import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'complete_profile_page.dart';
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
    bool _isGoogleLoading = false;
    String? _emailError;
    String? _passwordError;

    // ios client id (android'de kullanılmıyor) + web client id (idToken almak için android/ios ikisinde de gerekli)
    final _googleSignIn = GoogleSignIn(
        clientId: '498157770608-bf3uk1r7a7of1afal72md8a17i77qpfr.apps.googleusercontent.com',
        serverClientId: '498157770608-1apjf59m8l2ucv5ebh5qfhat5i8lhp2i.apps.googleusercontent.com',
    );

    Future<void> _handleGoogleSignIn() async {
        setState(() => _isGoogleLoading = true);
        try {
            final account = await _googleSignIn.signIn();
            if (account == null) {
                // kullanıcı iptal etti
                setState(() => _isGoogleLoading = false);
                return;
            }

            final auth = await account.authentication;
            final idToken = auth.idToken;
            if (idToken == null) {
                if (!mounted) return;
                setState(() => _isGoogleLoading = false);
                showAppSnackBar(context, 'Google girişi başarısız oldu, tekrar dener misin?', color: Colors.red);
                return;
            }

            final result = await _authService.loginWithGoogle(idToken);
            if (!mounted) return;
            setState(() => _isGoogleLoading = false);

            if (result['success'] == true) {
                final profileCompleted = result['data']['profileCompleted'] == true;
                if (profileCompleted) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomePage()),
                    );
                } else {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const CompleteProfilePage()),
                    );
                }
            } else {
                showAppSnackBar(context, result['message'], color: Colors.red);
            }
        } catch (e) {
            if (!mounted) return;
            setState(() => _isGoogleLoading = false);
            showAppSnackBar(context, 'Google girişi başarısız oldu, tekrar dener misin?', color: Colors.red);
        }
    }

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
                    onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                    ),
                    icon: _isGoogleLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                        )
                        : FaIcon(FontAwesomeIcons.google, color: Colors.red, size: 20),
                    label: Text('Google ile devam et'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                    onPressed: () {
                        showAppSnackBar(context, 'Yakında eklenecek.');
                    },
                    style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                    ),
                    icon: Icon(Icons.apple, size: 24),
                    label: Text('Apple ile devam et'),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                    );
                  },
                  child: const Text('Şifremi unuttum?'),
                ),
              ),
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