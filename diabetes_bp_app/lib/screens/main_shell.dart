import 'package:flutter/material.dart';
import 'patient/dashboard_screen.dart';
import 'patient/history_screen.dart';
import 'patient/medication_screen.dart';
import 'patient/profile_screen.dart';

/// Top-level mobile navigation shell.
///
/// Hosts the four primary destinations behind a Material 3
/// [NavigationBar]. An [IndexedStack] keeps each tab's state (scroll
/// position, Firestore streams, the History tab controller) alive when
/// switching tabs — the standard bottom-nav pattern on mobile.
///
/// Detail/entry screens that are actions rather than destinations
/// (the simulated glucometer and BP monitor) are still pushed on top
/// of this shell from the Home tab, so they get a normal back button.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _goToTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(onNavigate: _goToTab),
      const HistoryScreen(),
      const MedicationScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goToTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: 'Meds',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
