import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'main_screen.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  final _storage = FlutterSecureStorage();

  Future<void> _loginUser(String username, String password) async {
    final Uri apiUrl = Uri.parse('http://10.0.2.2:8000/api/accounts/login/');
    final response = await http.post(
      apiUrl,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      _handleSuccessfulLogin(response);
    } else {
      _showInvalidCredentialsMessage();
    }
  }

  void _handleSuccessfulLogin(http.Response response) async {
  final responseData = json.decode(response.body);
  await _storage.write(key: 'token', value: responseData['access']);
  await _storage.write(key: 'userId', value: responseData['user_id'].toString());
  await _storage.write(key: 'role', value: responseData['role']);
  await _storage.write(key: 'username', value: _username);  // Store the username

  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MainScreen()));
}


  void _showInvalidCredentialsMessage() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid Credentials')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: _buildLoginForm(),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _buildTextField('Username', false, (val) => _username = val),
        const SizedBox(height: 20),
        _buildTextField('Password', true, (val) => _password = val),
        const SizedBox(height: 20),
        _buildLoginButton(),
        const SizedBox(height: 20),
        _buildRegisterButton(),
      ],
    );
  }


  Widget _buildTextField(String label, bool isPassword, ValueChanged<String> onChanged) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        labelStyle: TextStyle(fontWeight: FontWeight.bold),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (isPassword && value.length < 8) {
          return 'Password must be at least 8 characters long';
        }
        return null;
      },
      obscureText: isPassword,
      onChanged: onChanged,
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: () {
        if (_formKey.currentState?.validate() ?? false) {
          _loginUser(_username, _password);
        }
      },
      child: Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        primary: Colors.blue,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return TextButton(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterPage())),
      child: Text(
        "Don't have an account?",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }
}
