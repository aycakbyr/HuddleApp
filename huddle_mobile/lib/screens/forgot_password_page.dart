import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/snackbar_helper.dart';
import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
    const ForgotPasswordPage({super.key});

    @override
    State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
    final _authService = AuthService();
    final _emailController = TextEditingController();
    bool _isLoading = false;
    String? _emailError;

    @override
    void dispose() {
        _emailController.dispose();
        super.dispose();
    }

    Future<void> _sendCode() async {
        final email = _emailController.text.trim();

        setState(() {
            _emailError = email.isEmpty ? 'Email boş bırakılamaz!' : null;
        });
        if (_emailError != null) return;

        setState(() => _isLoading = true);
        final result = await _authService.forgotPassword(email);
        if (!mounted) return;
        setState(() => _isLoading = false);

        if (result['success'] == true) {
            showAppSnackBar(context, result['data']['message'] ?? 'Kod gönderildi.');
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ResetPasswordPage(email: email)),
            );
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
                iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
                title: const Text('Şifremi Unuttum', style: TextStyle(color: Color(0xFF1A237E), fontSize: 18)),
            ),
            body: SafeArea(
                child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            const Text(
                                'Hesabına kayıtlı email adresini gir, sana 6 haneli bir sıfırlama kodu gönderelim.',
                                style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                    labelText: 'E-posta',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.email),
                                    errorText: _emailError,
                                ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                    onPressed: _isLoading ? null : _sendCode,
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
                                        : const Text('Kod Gönder'),
                                ),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }
}
