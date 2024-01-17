import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CreateListingPage extends StatefulWidget {
  @override
  _CreateListingPageState createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  final _formKey = GlobalKey<FormState>();
  final _storage = FlutterSecureStorage();
  String title = '';
  String description = '';
  double price = 0.0;
  List<String> selectedSkills = [];
  List<String> allSkills = []; // Placeholder for all available skills

  @override
  void initState() {
    super.initState();
    _fetchSkills();
  }

  Future<void> _fetchSkills() async {
    // Fetch skills from your backend
    // Example: http.get(url)
    // Update the 'allSkills' list with the fetched skills
  }

  Future<void> _submitListing() async {
    String? token = await _storage.read(key: 'token');
    final Uri apiUrl = Uri.parse('http://10.0.2.2:8000/api/listings/create/');
    final response = await http.post(
      apiUrl,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'price': price,
        'skills': selectedSkills,
      }),
    );

    if (response.statusCode == 201) {
      // Handle successful creation
      Navigator.pop(context);
    } else {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Listing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Title'),
                onChanged: (value) => title = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                onChanged: (value) => description = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                onChanged: (value) => price = double.tryParse(value) ?? 0,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  return null;
                },
              ),
              // Skill selection widget (e.g., dropdown, checkboxes)
              ...allSkills.map((skill) => CheckboxListTile(
                title: Text(skill),
                value: selectedSkills.contains(skill),
                onChanged: (bool? value) {
                  setState(() {
                    if (value ?? false) {
                      selectedSkills.add(skill);
                    } else {
                      selectedSkills.remove(skill);
                    }
                  });
                },
              )).toList(),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _submitListing();
                  }
                },
                child: Text('Submit Listing'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
