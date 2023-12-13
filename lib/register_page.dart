import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
    @override
    _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
    final _formKey = GlobalKey<FormState>();
    String username = '';
    String firstName = '';
    String lastName = '';
    String email = '';
    String password = '';
    String role = 'client';

    Future<void> registerUser() async {
        final response = await http.post(
            Uri.parse('http://10.0.2.2:8000/api/accounts/register/'),
            headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, String>{
                'username': username,
                'first_name': firstName,
                'last_name': lastName,
                'email': email,
                'password': password,
                'role': role,
            }),
        );

        if (response.statusCode == 201) {
            Navigator.pushNamed(context, '/login');
        } else {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to register')),
            );
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: Text('Register')),
            body: Form(
                key: _formKey,
                child: Column(
                    children: [
                        TextFormField(
                            decoration: InputDecoration(labelText: 'Username'),
                            onChanged: (value) => setState(() => username = value),
                        ),
                        TextFormField(
                            decoration: InputDecoration(labelText: 'First Name'),
                            onChanged: (value) => setState(() => firstName = value),
                        ),
                        TextFormField(
                            decoration: InputDecoration(labelText: 'Last Name'),
                            onChanged: (value) => setState(() => lastName = value),
                        ),
                        TextFormField(
                            decoration: InputDecoration(labelText: 'Email'),
                            onChanged: (value) => setState(() => email = value),
                        ),
                        TextFormField(
                            decoration: InputDecoration(labelText: 'Password'),
                            obscureText: true,
                            onChanged: (value) => setState(() => password = value),
                        ),
                        DropdownButtonFormField(
                            value: role,
                            items: ['client', 'freelancer'].map((String role) {
                                return DropdownMenuItem(
                                    value: role,
                                    child: Text(role),
                                );
                            }).toList(),
                            onChanged: (String? newValue) {
                                if (newValue != null) {
                                    setState(() {
                                        role = newValue;
                                    });
                                }
                            },
                        ),
                        ElevatedButton(
                            onPressed: () {
                                if (_formKey.currentState?.validate() ?? false) {
                                    registerUser();
                                }
                            },
                            child: Text('Register'),
                        ),
                    ],
                ),
            ),
        );
    }
}