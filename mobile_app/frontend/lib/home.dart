import 'package:flutter/material.dart';
import 'package:opsin/Pages/dashboard/dashboard.dart';
import 'package:opsin/Pages/drive/drive_analyze_page.dart';
import 'package:opsin/Pages/vehicle/garage.dart';
import 'package:opsin/Pages/navigation/map_page.dart';
import 'package:opsin/Widgets/gnav_bar.dart';
import 'package:opsin/Widgets/header.dart';
import 'package:opsin/core/constants/app_gradients.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int selectedIndex = 0;
  final GlobalKey<MapPageState> _mapPageKey = GlobalKey<MapPageState>();
  final GlobalKey<DriveAnalyzePageState> _driveAnalyzeKey =
      GlobalKey<DriveAnalyzePageState>();
  final GlobalKey<GaragePageState> _garageKey = GlobalKey<GaragePageState>();
  late final PageController _pageController;

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
        return 'Opsin';
      case 1:
        return 'analytics';
      case 2:
        return 'your garage';
      default:
        return 'Opsin';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppGradients.mainBackground),
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
                    DriveAnalyzePage(key: _driveAnalyzeKey),
                    GaragePage(key: _garageKey),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: GnavBar(
        selectedIndex: selectedIndex,
        onTabChange: onTabChange,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: FloatingActionButton.extended(
          onPressed: () {
            switch (selectedIndex) {
              case 0:
                Navigator.pushNamed(context, "/map-webview");
                break;
              case 1:
                _driveAnalyzeKey.currentState?.showFilterSheet();
                break;
              case 2:
                _garageKey.currentState?.showAddVehicleOverlay(context);
                break;
            }
          },
          backgroundColor: Theme.of(context).primaryColor,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              selectedIndex == 0
                  ? Icons.map_rounded
                  : selectedIndex == 1
                  ? Icons.tune_rounded
                  : Icons.add_rounded,
              key: ValueKey<int>(selectedIndex),
              color: Colors.white,
            ),
          ),
          label: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Text(
              selectedIndex == 0
                  ? 'Map'
                  : selectedIndex == 1
                  ? 'Filter'
                  : 'Add Vehicle',
              key: ValueKey<int>(selectedIndex),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
