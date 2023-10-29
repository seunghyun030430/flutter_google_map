import 'package:demo/pages/user/user_page.dart';
import 'package:flutter/material.dart';

import 'package:demo/widgets/search_widget.dart';
import 'package:demo/widgets/map_widget.dart';
import 'package:demo/pages/trail/trail_page.dart';
import 'package:demo/pages/threat/threat_page.dart';
import 'package:demo/pages/search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  static const String routeName = '/home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showMapWidget = true;
  bool _showSearchWidget = true;
  bool _showSearchPage = false;
  bool _showBottomNavigationBar = true;
  bool _showTrailPage = false;
  bool _showThreatPage = false;
  bool _showProfilePage = false;
  bool _showDraggableScrollableSheet = false;
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    if (index == 0) {
      setState(() {
        _selectedIndex = index;
        _showMapWidget = true;
        _showSearchWidget = true;
        _showProfilePage = false;
        _showTrailPage = false;
        _showThreatPage = false;
      });
    } else if (index == 1) {
      setState(() {
        _selectedIndex = index;
        _showMapWidget = false;
        _showSearchWidget = false;
        _showTrailPage = false;
        _showProfilePage = false;
        _showThreatPage = true;
      });
    } else if (index == 2) {
      setState(() {
        _selectedIndex = index;
        _showMapWidget = false;
        _showSearchWidget = false;
        _showProfilePage = false;
        _showTrailPage = true;
        _showThreatPage = true;
      });
    } else if (index == 3) {
      setState(() {
        _selectedIndex = index;
        _showMapWidget = false;
        _showProfilePage = true;
        _showTrailPage = false;
        _showSearchWidget = false;
        _showThreatPage = true;
      });
    }
  }

  onSearch(String query) {
    setState(() {
      _showBottomNavigationBar = false;
      _showDraggableScrollableSheet = false;
      _showSearchWidget = false;
      _showSearchPage = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _onItemTapped(_selectedIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          if (_showMapWidget) ...[MapWidget()],
          if (_showTrailPage) ...[TrailPage()],
          if (_showThreatPage) ...[ThreatPage()],
          if (_showProfilePage) ...[UserPage()],
          if (_showSearchWidget) ...[
            Positioned(
              top: MediaQuery.of(context).padding.top +
                  10, // Safe area consideration
              left: 10,
              right: 10,
              child: SearchWidget(onSearch: onSearch),
            )
          ],
          if (_showDraggableScrollableSheet) ...[
            DraggableScrollableSheet(
              initialChildSize: 0.2,
              minChildSize: 0.2,
              maxChildSize: 1,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Container(
                  color: Colors.white,
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: 25,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        title: Text('Item $index'),
                      );
                    },
                  ),
                );
              },
            ),
          ],
          if (_showBottomNavigationBar)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNavigationBar(
                backgroundColor: Colors.white,
                // backgroundColor: Colors.blue,
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.map),
                    label: 'Map',
                    backgroundColor: Colors.grey,
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.route_rounded),
                    label: 'Trails',
                    backgroundColor: Colors.grey,
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dangerous),
                    label: 'Threats',
                    backgroundColor: Colors.grey,
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                    backgroundColor: Colors.grey,
                  ),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Colors.white,
                onTap: _onItemTapped,
              ),
            ),
        ],
      ),
    );
  }
}
