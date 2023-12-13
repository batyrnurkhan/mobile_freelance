import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'register_page.dart'; // Import the register_page.dart file

class LoginPage extends StatefulWidget {
    @override
    _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
    final _formKey = GlobalKey<FormState>();
    String username = '';
    String password = '';
    final storage = FlutterSecureStorage();

    Future<void> loginUser(String username, String password) async {
        final response = await http.post(
            Uri.parse('http://10.0.2.2:8000/api/accounts/login/'),
            headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, String>{
                'username': username,
                'password': password,
            }),
        );

        if (response.statusCode == 200) {
            final responseData = json.decode(response.body);
            await storage.write(key: 'token', value: responseData['access']);
            Navigator.pushNamed(context, '/profile');
        } else {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Invalid Credentials')),
            );
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: Text('Login')),
            body: Form(
                key: _formKey,
                child: Column(
                    children: [
                        TextFormField(
                            decoration: InputDecoration(labelText: 'Username'),
                            onChanged: (value) => username = value,
                        ),
                        TextFormField(
                            decoration: InputDecoration(labelText: 'Password'),
                            obscureText: true,
                            onChanged: (value) => password = value,
                        ),
                        ElevatedButton(
                            onPressed: () {
                                if (_formKey.currentState?.validate() ?? false) {
                                    loginUser(username, password);
                                }
                            },
                            child: Text('Login'),
                        ),
                        TextButton(
                            onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => RegisterPage()), // Navigate to RegisterPage
                                );
                            },
                            child: Text("Don't have an account?"), // Display the button text
                        ),
                    ],
                ),
            ),
        );
    }
}
