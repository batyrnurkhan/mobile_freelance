import 'package:flutter/material.dart';
import './register_page.dart';
import './login_page.dart';
import './profile_page.dart';
import './in_progress_listing_page.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/profile': (context) => ProfilePage(),
        '/in_progress': (context) => InProgressListingsPage(), 
      },
    );
  }
}