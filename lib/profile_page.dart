import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic> userProfile = {};
  bool isLoading = true;
  final storage = FlutterSecureStorage();

  Future<void> fetchProfile() async {
    String? token = await storage.read(key: 'token');

    if (token != null) {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/accounts/profile/'),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          userProfile = json.decode(response.body);
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile')),
        );
        setState(() {
          isLoading = false;
        });
      }
    } else {
      // Handle the case where the token is null
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: isLoading 
        ? CircularProgressIndicator() 
        : userProfile['role'] == 'freelancer' 
            ? _buildFreelancerProfile(userProfile)
            : _buildClientProfile(userProfile),
    );
  }

  Widget _buildFreelancerProfile(Map<String, dynamic> profile) {
    return ListView(
      children: [
        Text('Username: ${profile['username']}'),
        Text('Email: ${profile['email']}'),
        Text('Portfolio: ${profile['portfolio']}'),
        Text('Skills: ${profile['skills'].join(', ')}'),
        Text('Average Rating: ${profile['average_rating']}'),
        // Displaying reviews
        ...profile['reviews'].map<Widget>((review) {
          return ListTile(
            title: Text('Rating: ${review['rating']}'),
            subtitle: Text(review['text']),
          );
        }).toList(),
        // Add more fields if needed
      ],
    );
  }

  Widget _buildClientProfile(Map<String, dynamic> profile) {
    return ListView(
      children: [
        Text('Username: ${profile['username']}'),
        Text('Email: ${profile['email']}'),
        Text('Company Name: ${profile['company_name']}'),
        Text('Company Website: ${profile['company_website']}'),
        Text('Contact Name: ${profile['contact_name']}'),
        Text('Preferred Communication: ${profile['preferred_communication']}'),
        // Add more fields if needed
      ],
    );
  }
}
