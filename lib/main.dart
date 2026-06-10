import 'package:flutter/material.dart';
import 'package:tramites_app/constants/colors_and_themes.dart';
import 'package:tramites_app/screens/main_navigation.dart';

void main() {
  runApp(const TramitesApp());
}

class TramitesApp extends StatelessWidget {
  const TramitesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consulta de Trámites',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          surface: surface,
          primary: accent,
        ),
        scaffoldBackgroundColor: bgDark,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}
