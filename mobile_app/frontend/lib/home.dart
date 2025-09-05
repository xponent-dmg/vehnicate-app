import 'package:flutter/material.dart';
import 'package:vehnicate_frontend/Pages/dashboard.dart';
import 'package:vehnicate_frontend/Pages/drive_analyze_page.dart';
import 'package:vehnicate_frontend/Pages/garage.dart';
import 'package:vehnicate_frontend/Pages/map_page.dart';
import 'package:vehnicate_frontend/Widgets/gnav_bar.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int selectedIndex = 0;
  final GlobalKey<MapPageState> _mapPageKey = GlobalKey<MapPageState>();

  List<Color> colors = [Colors.purple, Colors.pink, Colors.amber[600]!, Colors.teal];
  void onTabChange(int index) {
    setState(() => selectedIndex = index);
    if (index == 1) {
      _mapPageKey.currentState?.startLiveTracking();
    } else {
      _mapPageKey.currentState?.stopLiveTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: [DashboardPage(), MapPage(key: _mapPageKey), GaragePage(), DriveAnalyzePage()],
      ),
      bottomNavigationBar: GnavBar(selectedIndex: selectedIndex, onTabChange: onTabChange),
    );
  }
}
