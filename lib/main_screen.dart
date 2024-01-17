import 'package:flutter/material.dart';
import 'home_page.dart';
import 'freelancer_list_page.dart';
import 'profile_page.dart';
import 'chat_page.dart';
import 'in_progress_listing_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String userRole = 'client'; // Default role, will be updated based on actual user role
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    String? role = await storage.read(key: 'role');
    setState(() {
      userRole = role ?? 'client';
    });
  }

  List<Widget> get _widgetOptions => [
    HomePage(),
    if (userRole == 'client') FreelancerListPage(),
    InProgressListingsPage(),
    ChatPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          if (userRole == 'client')
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'Freelancers',
            ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hourglass_empty),
            label: 'In Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.black,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
        onTap: _onItemTapped,
      ),
    );
  }
}