import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EditListingPage extends StatefulWidget {
  final Map<String, dynamic> listing;

  EditListingPage({required this.listing});

  @override
  _EditListingPageState createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  final storage = FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _freelancerSearchController;
  String? _selectedStatus;
  List<String> selectedSkills = [];
  List<String> allSkills = [];
  String? _selectedSkillToAdd;
  String? _selectedFreelancer;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.listing['title']);
    _descriptionController = TextEditingController(text: widget.listing['description']);
    _priceController = TextEditingController(text: widget.listing['price'].toString());
    _freelancerSearchController = TextEditingController();
    _selectedStatus = widget.listing['status'];
    _selectedFreelancer = widget.listing['freelancer'];
    selectedSkills = List<String>.from(widget.listing['skills'] ?? []);
    fetchAllSkills();
  }

  Future<void> fetchAllSkills() async {
    String? token = await storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/accounts/skills/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        allSkills = List<String>.from(json.decode(response.body).map((s) => s['name']));
      });
    }
  }

  Future<void> updateListing() async {
  if (_formKey.currentState!.validate()) {
    String? token = await storage.read(key: 'token');
    final response = await http.patch(
      Uri.parse('http://10.0.2.2:8000/api/listings/${widget.listing['slug']}/update/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'price': _priceController.text,
        'status': _selectedStatus,
        'freelancer': _selectedFreelancer,
        'skills': selectedSkills,
      }),
    );

    if (response.statusCode == 200) {
      if (mounted) {
        Navigator.pop(context, json.decode(response.body));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update listing')));
      }
    }
  }
}



  Widget buildSkillsChips() {
    if (selectedSkills.isEmpty) {
      return SizedBox.shrink();
    }

    return Wrap(
      spacing: 6.0,
      children: selectedSkills.map((skill) {
        return Chip(
          label: Text(skill),
          onDeleted: () {
            setState(() {
              selectedSkills.remove(skill);
            });
          },
        );
      }).toList(),
    );
  }

  Future<Iterable<String>> fetchFreelancerSuggestions(String query) async {
    String? token = await storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/accounts/freelancers/?q=$query'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      var freelancers = json.decode(response.body) as List;
      return freelancers.where((f) => f['username'].contains(query)).map((f) => f['username'] as String);
    } else {
      return const Iterable<String>.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Listing'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
                ),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(labelText: 'Price'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a price' : null,
                ),
                buildSkillsChips(),
                DropdownButton<String>(
                  value: _selectedSkillToAdd,
                  hint: Text('Select Skill'),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSkillToAdd = newValue;
                      if (newValue != null && !selectedSkills.contains(newValue)) {
                        selectedSkills.add(newValue);
                      }
                    });
                  },
                  items: allSkills.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    } else {
                      return fetchFreelancerSuggestions(textEditingValue.text);
                    }
                  },
                  onSelected: (String selection) {
                    setState(() {
                      _selectedFreelancer = selection;
                      _freelancerSearchController.text = selection;
                    });
                  },
                  fieldViewBuilder: (
                    BuildContext context,
                    TextEditingController fieldTextEditingController,
                    FocusNode fieldFocusNode,
                    VoidCallback onFieldSubmitted
                  ) {
                    _freelancerSearchController = fieldTextEditingController;
                    return TextField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Search Freelancers',
                        suffixIcon: Icon(Icons.search)
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: updateListing,
                  child: Text('Update Listing'),
                  style: ElevatedButton.styleFrom(primary: Colors.deepPurple),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _freelancerSearchController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
