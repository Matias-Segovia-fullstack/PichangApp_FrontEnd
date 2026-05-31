import 'package:flutter/material.dart';
import 'match_sport_view.dart';
import 'chats_view.dart';

class HomeTabs extends StatefulWidget {
  const HomeTabs({super.key});

  @override
  State<HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<HomeTabs> {
  int _currentIndex = 0; // Controla qué pestaña está activa

  // Lista de las pantallas que se mostrarán sobre la barra
  final List<Widget> _pantallas = [
    const MatchSportView(), // Pestaña 0: Tu pantalla actual tipo Tinder
    const ChatsView(), // Pestaña 1
    const Center(child: Text('Pantalla de Perfil (Próximamente)', style: TextStyle(fontSize: 20))), // Pestaña 2
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pantallas[_currentIndex], // Muestra la pantalla según el ícono seleccionado
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Cambia de vista al hacer clic
          });
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // Mantiene los íconos fijos y limpios
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Descubrir',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}