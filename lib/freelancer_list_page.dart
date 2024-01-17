import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './freelancer_profile_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FreelancerListPage extends StatelessWidget {
  Future<List<Map<String, dynamic>>> fetchFreelancers() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8000/api/accounts/freelancers/'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load freelancers');
    }
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Freelancers'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            showSearch(context: context, delegate: FreelancerSearch());
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchFreelancers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No freelancers available.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var freelancer = snapshot.data![index];
                var profile = freelancer['freelancer_profile'] ?? {};
                var profileImageUrl = profile['profile_image'] as String?;
                var username = freelancer['username'] as String? ?? 'Unavailable';

                return ListTile(
                  leading: profileImageUrl != null
                      ? CircleAvatar(backgroundImage: CachedNetworkImageProvider(profileImageUrl))
                      : const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(username),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FreelancerProfilePage(username: username),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}

class FreelancerSearch extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder(
      future: searchFreelancers(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No freelancers found.'));
        } else {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var freelancer = snapshot.data![index];
              var user = freelancer['user'] ?? {};
              var username = user['username'] ?? 'Unavailable';
              var profileImageUrl = freelancer['profile_image'] != null
                  ? 'http://localhost:8000${freelancer['profile_image']}'
                  : null;

              return ListTile(
                leading: profileImageUrl != null
                    ? CircleAvatar(backgroundImage: CachedNetworkImageProvider(profileImageUrl))
                    : const CircleAvatar(child: Icon(Icons.person)),
                title: Text(username),
                subtitle: Text(user['email'] ?? ''),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FreelancerProfilePage(username: username),
                    ),
                  );
                },
              );
            },
          );
        }
      },
    );
  }


  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }

  Future<List<Map<String, dynamic>>> searchFreelancers(String query) async {
    final url = Uri.parse('http://10.0.2.2:8000/api/accounts/search/freelancers/?q=${query.isNotEmpty ? query : ''}');
    final response = await http.get(url);
    if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
        throw Exception('Failed to search freelancers');
    }
}
}
