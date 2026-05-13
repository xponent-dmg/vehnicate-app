import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:opsin/Pages/profile/constants/profile_constants.dart';
import 'package:opsin/Widgets/glass_lite_container.dart';

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
    return GlassLiteContainer(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      margin: const EdgeInsets.symmetric(horizontal: 17, vertical: 20),
      borderRadius: BorderRadius.circular(50),
      backgroundColor: ProfileConstants.cardBackground,
      child: GNav(
        gap: 8,
        color: Colors.grey[800],
        activeColor: Theme.of(context).primaryColor,
        iconSize: 25,
        tabBackgroundColor: Theme.of(context).primaryColor.withAlpha(30),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        tabs: const [
          GButton(icon: Icons.home, text: 'Home', semanticLabel: "Home"),
          GButton(
            icon: Icons.analytics,
            text: 'Analytics',
            semanticLabel: "Analytics",
          ),
          GButton(
            icon: Icons.directions_car,
            text: 'Garage',
            semanticLabel: "Garage",
          ),
        ],
        selectedIndex: selectedIndex,
        onTabChange: onTabChange,
      ),
    );
  }
}
