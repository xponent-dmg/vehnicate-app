import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:vehnicate_frontend/Pages/profile/constants/profile_constants.dart';

class GnavBar extends StatelessWidget {
  const GnavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChange,
  });
  final int selectedIndex;
  final Function(int) onTabChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      margin: const EdgeInsets.symmetric(horizontal: 17, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: ProfileConstants.cardBackground,
      ),
      child: GNav(
        gap: 8,
        color: Colors.grey[800],
        activeColor: Theme.of(context).primaryColor,
        iconSize: 25,
        tabBackgroundColor: Theme.of(context).primaryColor.withAlpha(30),
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        tabs: [
          GButton(icon: Icons.home, text: 'Home', semanticLabel: "Home"),
          GButton(icon: Icons.analytics, text: 'Analytics', semanticLabel: "Analytics"),
          GButton(icon: Icons.directions_car, text: 'Garage', semanticLabel: "Garage"),
        ],
        selectedIndex: selectedIndex,
        onTabChange: onTabChange,
      ),
    );
  }
}
