import 'package:flutter/material.dart';
import 'about_page.dart';
import 'login_page.dart';
import '../services/auth_service.dart';
import '../utils/snackbar_helper.dart';

class SettingsPage extends StatefulWidget {
    const SettingsPage({super.key});

    @override
    State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
    final _authService = AuthService();

    //şifre değiştirme diyaloğu
    Future<void> _openChangePasswordDialog() async {
        final currentController = TextEditingController();
        final newController = TextEditingController();
        final confirmController = TextEditingController();
        String? errorText;
        bool isLoading = false;

        await showDialog(
            context: context,
            builder: (dialogContext) {
                return StatefulBuilder(
                    builder: (dialogContext, setDialogState) {
                        Future<void> submit() async {
                            if (currentController.text.isEmpty || newController.text.isEmpty) {
                                setDialogState(() => errorText = 'Tüm alanları doldurmalısın.');
                                return;
                            }
                            if (newController.text.length < 6) {
                                setDialogState(() => errorText = 'Yeni şifre en az 6 karakter olmalı.');
                                return;
                            }
                            if (newController.text != confirmController.text) {
                                setDialogState(() => errorText = 'Yeni şifreler birbiriyle uyuşmuyor.');
                                return;
                            }

                            setDialogState(() {
                                isLoading = true;
                                errorText = null;
                            });

                            final result = await _authService.changePassword(
                                currentPassword: currentController.text,
                                newPassword: newController.text,
                            );

                            if (result['success'] == true) {
                                if (!dialogContext.mounted) return;
                                Navigator.pop(dialogContext);
                                if (!mounted) return;
                                showAppSnackBar(context, 'Şifren güncellendi.');
                            } else {
                                setDialogState(() {
                                    isLoading = false;
                                    errorText = result['message'];
                                });
                            }
                        }

                        return AlertDialog(
                            title: const Text('Şifre Değiştir'),
                            content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    TextField(
                                        controller: currentController,
                                        obscureText: true,
                                        decoration: const InputDecoration(labelText: 'Mevcut Şifre'),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                        controller: newController,
                                        obscureText: true,
                                        decoration: const InputDecoration(labelText: 'Yeni Şifre'),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                        controller: confirmController,
                                        obscureText: true,
                                        decoration: const InputDecoration(labelText: 'Yeni Şifre (Tekrar)'),
                                    ),
                                    if (errorText != null) ...[
                                        const SizedBox(height: 8),
                                        Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                                    ],
                                ],
                            ),
                            actions: [
                                TextButton(
                                    onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                                    child: const Text('Vazgeç'),
                                ),
                                TextButton(
                                    onPressed: isLoading ? null : submit,
                                    child: isLoading
                                        ? const SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                        : const Text('Değiştir'),
                                ),
                            ],
                        );
                    },
                );
            },
        );
    }

    //hesabı silme diyaloğu
    Future<void> _openDeleteAccountDialog() async {
        final passwordController = TextEditingController();
        String? errorText;
        bool isLoading = false;

        await showDialog(
            context: context,
            builder: (dialogContext) {
                return StatefulBuilder(
                    builder: (dialogContext, setDialogState) {
                        Future<void> submit() async {
                            if (passwordController.text.isEmpty) {
                                setDialogState(() => errorText = 'Şifreni girmelisin.');
                                return;
                            }

                            setDialogState(() {
                                isLoading = true;
                                errorText = null;
                            });

                            final result = await _authService.deleteAccount(passwordController.text);

                            if (result['success'] == true) {
                                if (!dialogContext.mounted) return;
                                Navigator.pop(dialogContext);
                                if (!mounted) return;
                                await _authService.logout();
                                if (!mounted) return;
                                Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (_) => const LoginPage()),
                                    (route) => false,
                                );
                            } else {
                                setDialogState(() {
                                    isLoading = false;
                                    errorText = result['message'];
                                });
                            }
                        }

                        return AlertDialog(
                            title: const Text('Hesabı Sil'),
                            content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    const Text(
                                        'Hesabını silmek istediğine emin misin? Bu işlem geri alınamaz, devam etmek için şifreni gir.',
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                        controller: passwordController,
                                        obscureText: true,
                                        decoration: const InputDecoration(labelText: 'Şifre'),
                                    ),
                                    if (errorText != null) ...[
                                        const SizedBox(height: 8),
                                        Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                                    ],
                                ],
                            ),
                            actions: [
                                TextButton(
                                    onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                                    child: const Text('Vazgeç'),
                                ),
                                TextButton(
                                    onPressed: isLoading ? null : submit,
                                    child: isLoading
                                        ? const SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                        : const Text('Hesabı Sil', style: TextStyle(color: Colors.red)),
                                ),
                            ],
                        );
                    },
                );
            },
        );
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: const Color(0xFFFAF7F2),
            appBar: AppBar(
                backgroundColor: const Color(0xFFFAF7F2),
                elevation: 0,
                iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
                title: const Text(
                    'Ayarlar',
                    style: TextStyle(color: Color(0xFF1A237E), fontSize: 18),
                ),
            ),
            body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                    Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                            children: [
                                ListTile(
                                    leading: const Icon(Icons.lock_outline, color: Color(0xFF1A237E)),
                                    title: const Text('Şifre Değiştir'),
                                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                    onTap: _openChangePasswordDialog,
                                ),
                                const Divider(height: 1),
                                ListTile(
                                    leading: const Icon(Icons.dark_mode_outlined, color: Color(0xFF1A237E)),
                                    title: const Text('Karanlık Mod'),
                                    trailing: Switch(
                                        value: false,
                                        onChanged: (value) {
                                            showAppSnackBar(context, 'Yakında eklenecek.');
                                        },
                                    ),
                                ),
                                const Divider(height: 1),
                                ListTile(
                                    leading: const Icon(Icons.info_outline, color: Color(0xFF1A237E)),
                                    title: const Text('Hakkında'),
                                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                    onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const AboutPage()),
                                        );
                                    },
                                ),
                                const Divider(height: 1),
                                ListTile(
                                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                                    title: const Text('Hesabı Sil', style: TextStyle(color: Colors.red)),
                                    onTap: _openDeleteAccountDialog,
                                ),
                            ],
                        ),
                    ),
                ],
            ),
        );
    }
}
