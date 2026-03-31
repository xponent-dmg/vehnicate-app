import 'package:flutter/material.dart';
import 'package:vehnicate_frontend/Pages/dashboard/dashboard.dart';
import 'package:vehnicate_frontend/Pages/drive/drive_analyze_page.dart';
import 'package:vehnicate_frontend/Pages/drive/sensor_debug_page.dart';
import 'package:vehnicate_frontend/Pages/vehicle/garage.dart';
import 'package:vehnicate_frontend/Pages/navigation/map_page.dart';
import 'package:vehnicate_frontend/Widgets/gnav_bar.dart';
import 'package:vehnicate_frontend/Widgets/header.dart';
import 'package:vehnicate_frontend/utils/extensions.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int selectedIndex = 0;
  final GlobalKey<MapPageState> _mapPageKey = GlobalKey<MapPageState>();
  late final PageController _pageController;

  List<Color> colors = [
    Colors.purple,
    Colors.pink,
    Colors.amber[600]!,
    Colors.teal,
  ];
  void onTabChange(int index) {
    setState(() => selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.ease,
    );
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

  String _getPageName(int index) {
    switch (index) {
      case 0:
        return context.loc.vehnicateTab;
      case 1:
        return context.loc.navigationTab;
      case 2:
        return context.loc.garageTab;
      case 3:
        return context.loc.analyticsTab;
      default:
        return context.loc.vehnicateTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.8, 1],
            colors: [Colors.black, Color(0xFF191B33), Color(0xFF292D54)],
          ),
        ),
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Header(
                pageName: _getPageName(selectedIndex),
                pageIndex: selectedIndex,
              ),
            ),
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
                  children: [
                    DashboardPage(),
                    SensorDebugPage(),
                    GaragePage(),
                    DriveAnalyzePage(),
                  ],
                ),
              ),
            ),
            GnavBar(selectedIndex: selectedIndex, onTabChange: onTabChange),
          ],
        ),
      ),
      // bottomNavigationBar: GnavBar(
      //   selectedIndex: selectedIndex,
      //   onTabChange: onTabChange,
      // ),
    );
  }
}
