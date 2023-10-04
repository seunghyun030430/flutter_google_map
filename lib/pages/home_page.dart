import 'package:flutter/material.dart';
import 'package:demo/widgets/map_widget.dart';
import 'package:demo/pages/profile_page.dart';
import 'package:demo/pages/firestore_page.dart';
import 'package:demo/pages/search_page.dart';
import 'package:demo/widgets/search_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  static const String routeName = '/home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showSearchWidget = true;
  bool _showBottomNavigationBar = true;
  bool _showSearchPage = false;
  bool _showProfilePage = false;
  bool _showDraggableScrollableSheet = true;
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    if (index == 2) {
      setState(() {
        _selectedIndex = index;
        _showProfilePage = true;
        _showSearchWidget = false;
        _showDraggableScrollableSheet = false;
      });
    } else {
      setState(() {
        _selectedIndex = index;
        _showProfilePage = false;
        _showSearchWidget = true;
        _showDraggableScrollableSheet = true;
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
          MapWidget(),
          if (_showProfilePage) ...[FirestorePage()],
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
                // backgroundColor: Colors.blue,
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.map),
                    label: 'Map',
                    backgroundColor: Colors.blue,
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                    backgroundColor: Colors.blue,
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                    backgroundColor: Colors.blue,
                  ),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Colors.amber[800],
                onTap: _onItemTapped,
              ),
            ),
        ],
      ),
    );
  }
}
