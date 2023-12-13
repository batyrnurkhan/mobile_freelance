import 'package:flutter/material.dart';
import './register_page.dart'; // Adjust the import path as needed
import './login_page.dart';   // Adjust the import path as needed
import './profile_page.dart'; // Adjust the import path as needed

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
      home: LoginPage(), // Starting page of the app
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/profile': (context) => ProfilePage(),
      },
    );
  }
}
