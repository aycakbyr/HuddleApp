import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutPage extends StatelessWidget {
    const AboutPage({super.key});

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: const Color(0xFFFAF7F2),
            appBar: AppBar(
                backgroundColor: const Color(0xFFFAF7F2),
                elevation: 0,
                iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
                title: const Text(
                    '',
                    style: TextStyle(color: Color(0xFF1A237E), fontSize: 18),
                ),
            ),
            body: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Center(
                            child: Column(
                                children: [
                                    Text(
                                        'Huddle',
                                        style: GoogleFonts.pacifico(fontSize: 32, color: const Color(0xFF1A237E)),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text('Sürüm x.x.x', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                            ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                            'Huddle, çevrendeki etkinlikleri keşfetmen, yeni etkinlikler oluşturman ve insanlarla bir araya gelmen için tasarlandı. ',
                            style: TextStyle(fontSize: 14, height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                            'Geliştirici: Ayça',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                    ],
                ),
            ),
        );
    }
}