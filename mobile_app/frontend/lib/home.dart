import 'package:flutter/material.dart';
import 'package:vehnicate_frontend/Pages/dashboard/dashboard.dart';
import 'package:vehnicate_frontend/Pages/drive/drive_analyze_page.dart';
import 'package:vehnicate_frontend/Pages/drive/sensor_debug_page.dart';
import 'package:vehnicate_frontend/Pages/vehicle/garage.dart';
import 'package:vehnicate_frontend/Pages/navigation/map_page.dart';
import 'package:vehnicate_frontend/Widgets/gnav_bar.dart';
import 'package:vehnicate_frontend/Widgets/header.dart';
import 'package:vehnicate_frontend/Pages/profile/constants/profile_constants.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int selectedIndex = 0;
  final GlobalKey<MapPageState> _mapPageKey = GlobalKey<MapPageState>();
  late final PageController _pageController;

  List<Color> colors = [Colors.purple, Colors.pink, Colors.amber[600]!, Colors.teal];
  void onTabChange(int index) {
    setState(() => selectedIndex = index);
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 250), curve: Curves.ease);
    if (index == 1) {
      _mapPageKey.currentState?.startLiveTracking();
    } else {
      _mapPageKey.currentState?.stopLiveTracking();
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileConstants.primaryBackground,
      body: Column(
        children: [
          const SafeArea(bottom: false, child: Header()),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => selectedIndex = index);
                  if (index == 1) {
                    _mapPageKey.currentState?.startLiveTracking();
                  } else {
                    _mapPageKey.currentState?.stopLiveTracking();
                  }
                },
                // children: [DashboardPage(), MapPage(key: _mapPageKey), GaragePage(), DriveAnalyzePage()],
                children: [DashboardPage(), SensorDebugPage(), GaragePage(), DriveAnalyzePage()],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: GnavBar(selectedIndex: selectedIndex, onTabChange: onTabChange),
    );
  }
}
