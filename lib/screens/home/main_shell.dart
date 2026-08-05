import 'package:flutter/material.dart';
import '../chat/ai_chat_screen.dart';
import '../profile/profile_screen.dart';
import '../tape/live_tape_screen.dart';
import '../watchlist/watchlist_screen.dart';
import 'home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // Live tape takes the second slot — it's the core "why open this app"
  // surface. Search is still reachable from Home's app bar.
  static const _screens = [
    HomeScreen(),
    LiveTapeScreen(),
    AiChatScreen(),
    WatchlistScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.bolt_outlined), label: 'Live'),
          NavigationDestination(icon: Icon(Icons.smart_toy_outlined), label: 'AI'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Watchlist'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
