import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'edit_profile_page.dart';
import 'listing_detail_page.dart';
import 'freelancer_profile_page.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic> userProfile = {};
  List<dynamic> matchedListings = [];
  List<dynamic> matchedFreelancers = [];
  bool isLoading = true;
  final storage = FlutterSecureStorage();
  VideoPlayerController? _controller;
  bool _isVideoLoading = false;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> fetchProfile() async {
    String? token = await storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/accounts/profile/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final profileData = json.decode(response.body);
      setState(() {
        userProfile = profileData;
        isLoading = false;
        if (userProfile['profile_video'] != null) {
          initializeVideoPlayer(userProfile['profile_video']);
        }
      });
      if (profileData['role'] == 'freelancer') {
        fetchMatchedListings();
      } else if (profileData['role'] == 'client') {
        fetchMatchedFreelancers();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchMatchedListings() async {
    String? token = await storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/listings/open/matched/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        matchedListings = json.decode(response.body);
      });
    }
  }

  Future<void> fetchMatchedFreelancers() async {
    String? token = await storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/listings/client/matched_freelancers/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        matchedFreelancers = json.decode(response.body);
      });
    }
  }

  void initializeVideoPlayer(String videoUrl) {
    _controller = VideoPlayerController.network(videoUrl)
      ..initialize().then((_) {
        setState(() {
          _isVideoLoading = false;
        });
      });
    _controller?.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfilePage(userProfile: userProfile))
              );
            },
          ),
        ],
      ),
      body: isLoading ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: userProfile['role'] == 'freelancer' ? _buildFreelancerProfileWidgets() : _buildClientProfileWidgets(),
              ),
            ),
          ),
    );
  }

   List<Widget> _buildFreelancerProfileWidgets() {
    String fullName = (userProfile['first_name'] ?? '') + ' ' + (userProfile['last_name'] ?? '');

    return [
      _buildProfileHeader(),
      _buildProfileSection('Full Name', fullName.isNotEmpty ? fullName : 'Not provided'),
      _buildProfileSection('Username', userProfile['username'] ?? 'Not provided'),
      _buildProfileSection('Email', userProfile['email'] ?? 'Not provided'),
      _buildProfileSection('Skills', userProfile['skills']?.join(', ') ?? 'Not provided'),
      _buildProfileSection('Portfolio', userProfile['portfolio'] ?? 'Not provided'),
      _buildProfileSection('Average Rating', userProfile['average_rating']?.toString() ?? 'Not provided'),
      _buildProfileSection('Total Reviews', userProfile['total_reviews']?.toString() ?? 'Not provided'),
      _buildMatchedListingsSection(),
    ];
  }

  List<Widget> _buildClientProfileWidgets() {
    return [
      _buildProfileHeader(),
      _buildProfileSection('Company Website', userProfile['company_website'] ?? 'Not provided'),
      _buildProfileSection('Company Name', userProfile['company_name'] ?? 'Not provided'),
      _buildProfileSection('Contact Name', "${userProfile['first_name'] ?? ''} ${userProfile['last_name'] ?? ''}"),
      _buildProfileSection('Contact Email', userProfile['contact_email'] ?? 'Not provided'),
      _buildProfileSection('Preferred Communication', userProfile['preferred_communication'] ?? 'Not provided'),
      _buildMatchedFreelancersSection(),
    ];
  }

  Widget _buildProfileHeader() {
  String? profileImageUrl = userProfile['profile_image'];
  Widget imageWidget;

  if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
    String fullImageUrl = 'http://10.0.2.2:8000' + profileImageUrl;

    // Use CachedNetworkImageProvider to load the image
    imageWidget = CircleAvatar(
      radius: 40,
      backgroundImage: CachedNetworkImageProvider(fullImageUrl),
      backgroundColor: Colors.transparent,
      onBackgroundImageError: (exception, stackTrace) {
        // Handle any errors
        print('Error loading profile image: $exception');
      },
    );
  } else {
    imageWidget = CircleAvatar(
      radius: 40,
      backgroundImage: AssetImage('assets/default-avatar.png'),
      backgroundColor: Colors.transparent,
    );
  }
  return Column(
    children: [
      Container(
        padding: EdgeInsets.all(16),
        margin: EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColorLight,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            imageWidget,
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userProfile['username'] ?? 'Username not provided', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                  Text(userProfile['email'] ?? 'Email not provided', style: TextStyle(fontSize: 16, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
      if (userProfile.containsKey('profile_video') && userProfile['profile_video'] != null)
        _isVideoLoading ? CircularProgressIndicator() : AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: VideoPlayer(_controller!)),
    ],
  );
}

  Widget _buildProfileSection(String title, String? content) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(content ?? 'Not available'),
      ),
    );
  }

  Widget _buildMatchedListingsSection() {
    return matchedListings.isNotEmpty
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: matchedListings.map((listing) => ListTile(
            title: Text(listing['title']),
            subtitle: Text(listing['description']),
            trailing: Text('Skills: ${listing['skills']?.join(', ') ?? 'None'}'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ListingDetailPage(slug: listing['slug'])));
            },
          )).toList(),
        )
      : Text('No matched listings found.');
  }

  Widget _buildMatchedFreelancersSection() {
    return matchedFreelancers.isNotEmpty
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: matchedFreelancers.map((freelancer) {
            var skills = freelancer['skills'] ?? [];
            return ListTile(
              title: Text(freelancer['user']['username']),
              subtitle: Text('Skills: ${skills.join(', ')}'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => FreelancerProfilePage(username: freelancer['user']['username'])));
              },
            );
          }).toList(),
        )
      : Text('No matched freelancers found.');
  }
}
