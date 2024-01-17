import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'chat_detail_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FreelancerProfilePage extends StatefulWidget {
  final String username;

  FreelancerProfilePage({required this.username});

  @override
  _FreelancerProfilePageState createState() => _FreelancerProfilePageState();
}

class _FreelancerProfilePageState extends State<FreelancerProfilePage> {
  VideoPlayerController? _controller;
  Future<void>? _initializeVideoPlayerFuture;
  bool isLoading = true;
  final storage = FlutterSecureStorage();

  Future<Map<String, dynamic>> fetchFreelancerProfile() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/accounts/freelancer/${widget.username}/'),
    );
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data['introduction_video'] != null) {
        _controller = VideoPlayerController.network(data['introduction_video']);
        _initializeVideoPlayerFuture = _controller!.initialize();
        _controller!.setLooping(true);
      }
      return data;
    } else {
      throw Exception('Failed to load freelancer profile');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchFreelancerProfile().then((_) {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> navigateToChat() async {
    final token = await storage.read(key: 'token');
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/chats/create/${widget.username}/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 201) {
      final chatData = json.decode(response.body);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailPage(chat: chatData),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start or join chat with freelancer'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Freelancer Profile'),
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FutureBuilder<Map<String, dynamic>>(
                  future: fetchFreelancerProfile(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: Text('No profile found.'));
                    } else {
                      var freelancer = snapshot.data!;
                      var userProfile = freelancer['user'];
                      var skills = freelancer['skills'] ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (freelancer['profile_image'] != null)
                            Center(
                              child: CircleAvatar(
                                backgroundImage: NetworkImage(freelancer['profile_image']),
                                radius: 50,
                              ),
                            ),
                          SizedBox(height: 16),
                          Text(
                            "${userProfile['first_name'] ?? ''} ${userProfile['last_name'] ?? ''}",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          SizedBox(height: 4),
                          if (skills.isNotEmpty)
                            Text(
                              skills.join(', '),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          SizedBox(height: 24),
                          Card(
                            color: Colors.blue.shade50,
                            child: ListTile(
                              title: Text(
                                'Username',
                                style: TextStyle(color: Colors.blue.shade800),
                              ),
                              subtitle: Text(userProfile['username'] ?? ''),
                            ),
                          ),
                          Card(
                            color: Colors.blue.shade50,
                            child: ListTile(
                              title: Text(
                                'Email',
                                style: TextStyle(color: Colors.blue.shade800),
                              ),
                              subtitle: Text(userProfile['email'] ?? ''),
                            ),
                          ),
                          Card(
                            color: Colors.blue.shade50,
                            child: ListTile(
                              title: Text(
                                'Portfolio',
                                style: TextStyle(color: Colors.blue.shade800),
                              ),
                              subtitle: Text(freelancer['portfolio'] ?? ''),
                            ),
                          ),
                          Card(
                            color: Colors.blue.shade50,
                            child: ListTile(
                              title: Text(
                                'Average Rating',
                                style: TextStyle(color: Colors.blue.shade800),
                              ),
                              subtitle: Text(freelancer['average_rating'].toString()),
                            ),
                          ),
                          ElevatedButton(
                            child: Text('Chat with Freelancer'),
                            onPressed: navigateToChat,
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
    );
  }
}
