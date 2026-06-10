import 'package:flutter/material.dart';
import 'package:tramites_app/constants/colors_and_themes.dart';
import 'package:tramites_app/screens/home_screen.dart';
import 'package:tramites_app/screens/assignment_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

  void _onSearchRequested(String email) {
    setState(() {
      _currentIndex = 0; // Tab 0 is HomeScreen
    });
    // Trigger search after layout has switched tabs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homeKey.currentState?.searchForEmail(email);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(key: _homeKey),
      AssignmentScreen(onSearchRequested: _onSearchRequested),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: dividerColor, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: surface,
          selectedItemColor: accentSoft,
          unselectedItemColor: textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              activeIcon: Icon(Icons.search_rounded, color: accentSoft),
              label: 'Consultar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline_rounded),
              activeIcon: Icon(Icons.add_circle_rounded, color: accentSoft),
              label: 'Nuevo Trámite',
            ),
          ],
        ),
      ),
    );
  }
}
