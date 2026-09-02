import 'package:flutter/material.dart';
import 'about_page.dart';
import '../utils/snackbar_helper.dart';

class SettingsPage extends StatefulWidget {
    const SettingsPage({super.key});

    @override
    State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
                                    onTap: () {
                                        showAppSnackBar(context, 'Yakında eklenecek.'
                                        );
                                    },
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
                                    onTap: () {
                                        showAppSnackBar
                                        (context, 'Yakında eklenecek.');
                                    },
                                ),
                            ],
                        ),
                    ),
                ],
            ),
        );
    }
}