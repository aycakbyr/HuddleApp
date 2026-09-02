import 'package:flutter/material.dart';
import 'screens/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp ({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:'Huddle',
      debugShowCheckedModeBanner: false, //sağ üstteki debug yazısını kaldırır 
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true, //google ın en güncel tasarım dili
      ),
      home: const LoginPage(), // uygulama açılınca loginpage ekranı gösterilecek
    );
  }
}

