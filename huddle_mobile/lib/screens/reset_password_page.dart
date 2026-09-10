import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/snackbar_helper.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
    final String email;

    const ResetPasswordPage({super.key, required this.email});

    @override
    State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
    final _authService = AuthService();
    final _codeController = TextEditingController();
    final _newPasswordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();
    bool _isLoading = false;
    String? _codeError;
    String? _passwordError;

    @override
    void dispose() {
        _codeController.dispose();
        _newPasswordController.dispose();
        _confirmPasswordController.dispose();
        super.dispose();
    }

    Future<void> _resetPassword() async {
        final code = _codeController.text.trim();
        final newPassword = _newPasswordController.text;
        final confirmPassword = _confirmPasswordController.text;

        setState(() {
            _codeError = code.isEmpty ? 'Kodu girmelisin!' : null;
            _passwordError = newPassword.isEmpty
                ? 'Yeni şifre boş bırakılamaz!'
                : newPassword.length < 6
                    ? 'Şifre en az 6 karakterli olmalı!'
                    : newPassword != confirmPassword
                        ? 'Şifreler birbiriyle uyuşmuyor!'
                        : null;
        });
        if (_codeError != null || _passwordError != null) return;

        setState(() => _isLoading = true);
        final result = await _authService.resetPassword(
            email: widget.email,
            code: code,
            newPassword: newPassword,
        );
        if (!mounted) return;
        setState(() => _isLoading = false);

        if (result['success'] == true) {
            showAppSnackBar(context, result['data']['message'] ?? 'Şifren sıfırlandı.');
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
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
            appBar: AppBar(
                backgroundColor: const Color(0xFFFAF7F2),
                elevation: 0,
                iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
                title: const Text('Kodu Doğrula', style: TextStyle(color: Color(0xFF1A237E), fontSize: 18)),
            ),
            body: SafeArea(
                child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(
                                '${widget.email} adresine gönderilen kodu ve yeni şifreni gir.',
                                style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                                controller: _codeController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                    labelText: 'Sıfırlama Kodu',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.pin_outlined),
                                    errorText: _codeError,
                                ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                                controller: _newPasswordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                    labelText: 'Yeni Şifre',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.lock_outline),
                                ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                    labelText: 'Yeni Şifre (Tekrar)',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    errorText: _passwordError,
                                ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                    onPressed: _isLoading ? null : _resetPassword,
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
                                        : const Text('Şifreyi Sıfırla'),
                                ),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }
}
