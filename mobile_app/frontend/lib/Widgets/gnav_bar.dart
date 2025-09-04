import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:vehnicate_frontend/Pages/profile_page.dart';

class GnavBar extends StatelessWidget {
  GnavBar({super.key, required this.selectedIndex, required this.onTabChange});
  final int selectedIndex;
  final Function(int) onTabChange;
  final List<Color> colors = [Colors.purple, Colors.pink, Colors.amber[600]!, Colors.teal];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ProfileConstants.cardBackground,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),
      child: GNav(
        gap: 8,
        color: Colors.grey[800],
        activeColor: colors[selectedIndex],
        iconSize: 24,
        tabBackgroundColor: colors[selectedIndex].withAlpha(30),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        tabs: [
          GButton(icon: Icons.home, text: 'Home'),
          // GButton(icon: Icons.location_on, text: 'Location'),
          GButton(icon: Icons.directions_car, text: 'Garage'),
          GButton(icon: Icons.analytics, text: 'Analytics'),
        ],
        selectedIndex: selectedIndex,
        onTabChange: onTabChange,
      ),
    );
  }
}
