import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'map_screen.dart';

class MainScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const MainScreen({super.key, required this.cameras});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(cameras: widget.cameras),
      const HistoryScreen(),
      const MapScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07), width: 1)),
          ),
          child: BottomNavigationBar(
            backgroundColor: const Color(0xFF111A12),
            selectedItemColor: const Color(0xFF7AAD70),
            unselectedItemColor: Colors.white.withOpacity(0.3),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            currentIndex: _currentIndex,
            onTap: (idx) => setState(() => _currentIndex = idx),
            items: const [
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.camera_alt)),
                label: "Kamera"
              ),
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.history)),
                label: "Geçmiş"
              ),
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.map_outlined)),
                label: "Harita"
              ),
            ],
          ),
        ),
      ),
    );
  }
}

