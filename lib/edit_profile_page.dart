import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'login_page.dart';

class Skill {
  final int id;
  final String name;
  Skill({required this.id, required this.name});
  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(id: json['id'], name: json['name']);
  }
}

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  EditProfilePage({required this.userProfile});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final FlutterSecureStorage storage = FlutterSecureStorage();
  List<Skill> availableSkills = [];
  Set<int> selectedSkillIds = Set();
  late String email, portfolio, firstName, lastName, companyWebsite, companyName, preferredCommunication, profileVideoUrl, introductionVideoUrl;
  late bool isClient;
  XFile? _profileImage;

  @override
  void initState() {
    super.initState();
    email = widget.userProfile['email'] ?? '';
    portfolio = widget.userProfile['portfolio'] ?? '';
    firstName = widget.userProfile['first_name'] ?? '';
    lastName = widget.userProfile['last_name'] ?? '';
    companyWebsite = widget.userProfile['company_website'] ?? '';
    companyName = widget.userProfile['company_name'] ?? '';
    preferredCommunication = widget.userProfile['preferred_communication'] ?? 'email';
    profileVideoUrl = widget.userProfile['profile_video'] ?? '';
    introductionVideoUrl = widget.userProfile['introduction_video'] ?? '';
    isClient = widget.userProfile['role'] == 'client';
    fetchSkills();
  }

  Future<void> pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _profileImage = image;
    });
  }

  Future<List<Skill>> fetchSkills() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8000/api/accounts/skills/'));
    if (response.statusCode == 200) {
      List<dynamic> skillsJson = json.decode(response.body);
      List<Skill> skills = skillsJson.map((json) => Skill.fromJson(json)).toList();
      setState(() {
        availableSkills = skills;
        selectedSkillIds = Set.from(widget.userProfile['skills']?.map((s) {
          if (s is int) return s;
          if (s is String) return int.tryParse(s) ?? 0;
          if (s is Map<String, dynamic> && s.containsKey('id')) {
            return s['id'] is int ? s['id'] : int.tryParse(s['id'].toString()) ?? 0;
          }
          return 0;
        }).where((id) => id != 0) ?? []);
      });
      return skills;
    } else {
      throw Exception('Failed to load skills');
    }
  }

Future<void> updateProfile() async {
  String? token = await storage.read(key: 'token');
  final uri = Uri.parse('http://10.0.2.2:8000/api/accounts/profile/update/');
  final headers = {
    'Authorization': 'Bearer $token',
    // Removed 'Content-Type': 'application/json', to allow multipart
  };

  var request = http.MultipartRequest('PUT', uri)
    ..headers.addAll(headers)
    ..fields['email'] = email
    ..fields['first_name'] = firstName
    ..fields['last_name'] = lastName;

  // Append each skill ID as a separate entry
  selectedSkillIds.forEach((id) {
    request.fields['skill_ids[]'] = id.toString();
  });

  if (!isClient) {
    request.fields['portfolio'] = portfolio;
    if (introductionVideoUrl.isNotEmpty) {
      request.fields['introduction_video'] = introductionVideoUrl;
    }
  } else {
    request.fields['company_website'] = companyWebsite;
    request.fields['company_name'] = companyName;
    request.fields['preferred_communication'] = preferredCommunication;
    if (profileVideoUrl.isNotEmpty) {
      request.fields['profile_video'] = profileVideoUrl;
    }
  }

  if (_profileImage != null) {
    request.files.add(await http.MultipartFile.fromPath('profile_image', _profileImage!.path));
  }

  var response = await request.send();
  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
  } else {
    response.stream.transform(utf8.decoder).listen((value) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile: $value')));
    });
  }
}

  List<String> getSkillNamesFromIds(Set<int> ids) {
    return availableSkills.where((skill) => ids.contains(skill.id)).map((skill) => skill.name).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        actions: [IconButton(icon: Icon(Icons.logout), onPressed: logoutUser)],
      ),
      body: buildProfileForm(),
    );
  }

  Widget buildProfileForm() {
    return ListView(
      padding: EdgeInsets.all(12.0),
      children: [
        ElevatedButton(onPressed: pickImage, child: Text('Pick Profile Image')),
        if (_profileImage != null) Image.file(File(_profileImage!.path)),
        TextFormField(initialValue: email, onChanged: (val) => email = val, decoration: InputDecoration(labelText: 'Email')),
        TextFormField(initialValue: portfolio, onChanged: (val) => portfolio = val, decoration: InputDecoration(labelText: 'Portfolio URL')),
        TextFormField(initialValue: firstName, onChanged: (val) => firstName = val, decoration: InputDecoration(labelText: 'First Name')),
        TextFormField(initialValue: lastName, onChanged: (val) => lastName = val, decoration: InputDecoration(labelText: 'Last Name')),
        if (isClient) buildClientFields(),
        if (!isClient) buildFreelancerFields(),
        if (!isClient) buildSkillsList(),
        ElevatedButton(onPressed: updateProfile, child: Text('Update Profile')),
      ],
    );
  }

  Widget buildClientFields() {
    return Column(
      children: [
        TextFormField(initialValue: companyWebsite, onChanged: (val) => companyWebsite = val, decoration: InputDecoration(labelText: 'Company Website')),
        TextFormField(initialValue: companyName, onChanged: (val) => companyName = val, decoration: InputDecoration(labelText: 'Company Name')),
        DropdownButtonFormField(
          value: preferredCommunication,
          onChanged: (String? newValue) {
            setState(() {
              preferredCommunication = newValue!;
            });
          },
          items: <String>['email', 'chat', 'phone'].map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          decoration: InputDecoration(labelText: 'Preferred Communication'),
        ),
        TextFormField(initialValue: profileVideoUrl, onChanged: (val) => profileVideoUrl = val, decoration: InputDecoration(labelText: 'Profile Video URL')),
      ],
    );
  }

  Widget buildFreelancerFields() {
    return TextFormField(initialValue: introductionVideoUrl, onChanged: (val) => introductionVideoUrl = val, decoration: InputDecoration(labelText: 'Introduction Video URL'));
  }

  Widget buildSkillsList() {
    return Column(
      children: availableSkills.map((skill) {
        return CheckboxListTile(
          title: Text(skill.name),
          value: selectedSkillIds.contains(skill.id),
          onChanged: (bool? value) {
            setState(() {
              if (value ?? false) {
                selectedSkillIds.add(skill.id);
              } else {
                selectedSkillIds.remove(skill.id);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Future<void> logoutUser() async {
    await storage.delete(key: 'token');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()), 
      (Route<dynamic> route) => false
    );
  }
}

