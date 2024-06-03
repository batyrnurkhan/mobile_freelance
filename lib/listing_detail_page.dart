import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'edit_listing_page.dart';
import 'review_page.dart';  // Ensure this page is correctly implemented

class ListingDetailPage extends StatefulWidget {
  final String slug;

  ListingDetailPage({required this.slug});

  @override
  _ListingDetailPageState createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage> {
  final storage = FlutterSecureStorage();
  Map<String, dynamic>? listingDetails;
  String? userRole;
  String? username;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
    fetchListingDetails();
  }

  Future<void> fetchUserDetails() async {
    String? role = await storage.read(key: 'role');
    String? user = await storage.read(key: 'username');
    setState(() {
      userRole = role;
      username = user;
    });
  }

  Future<void> fetchListingDetails() async {
    String? token = await storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/listings/${widget.slug}/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        listingDetails = data;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void navigateToEditPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditListingPage(listing: listingDetails!)),
    );
  }

  void showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      )
    );
  }

  void navigateToReviewPage() {
    print("Navigating to Review Page with listingDetails: $listingDetails");
    if (listingDetails == null || !listingDetails!.containsKey('freelancer') || listingDetails!['freelancer'] == null) {
      showErrorSnackbar("Freelancer details are unavailable.");
      return;
    }

    var freelancer = listingDetails!['freelancer'];
    if (freelancer is String) {
      print("Freelancer username: $freelancer");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReviewPage(freelancerUsername: freelancer)),
      );
    } else {
      showErrorSnackbar("Freelancer data is not a valid string.");
      print("Freelancer data type is incorrect: ${freelancer.runtimeType}");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    bool isOwner = listingDetails?['user'] == username;
    bool canReview = userRole == 'client' && (listingDetails?['status'] == 'in_progress' || listingDetails?['status'] == 'closed');

    return Scaffold(
      appBar: AppBar(
        title: Text('Listing Details'),
        backgroundColor: Colors.deepPurple,
        actions: [
          if (isOwner)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: navigateToEditPage,
            ),
        ],
      ),
      body: buildListingDetails(),
      floatingActionButton: canReview ? FloatingActionButton(
        onPressed: navigateToReviewPage,
        child: Icon(Icons.rate_review),
        backgroundColor: Colors.purple,
      ) : null,
    );
  }

  Widget buildListingDetails() {
    if (listingDetails == null) {
      return Text('No data available');
    }

    final String baseUrl = 'http://10.0.2.2:8000';
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Card(
          elevation: 4.0,
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (listingDetails!['owner_profile_picture'] != null && listingDetails!['owner_profile_picture'].isNotEmpty)
                  Center(
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(baseUrl + listingDetails!['owner_profile_picture']),
                      radius: 40.0,
                    ),
                  ),
                SizedBox(height: 10),
                buildDetailRow('Title', listingDetails!['title']),
                buildDetailRow('Description', listingDetails!['description']),
                buildDetailRow('Price', '\$${listingDetails!['price']}'),
                buildDetailRow('Status', listingDetails!['status']),
                buildDetailRow('Client', listingDetails!['user']),
                buildDetailRow('Freelancer', listingDetails!['freelancer'] ?? 'N/A'),
                buildSkillsSection(listingDetails!['skills'] ?? []),
                buildDetailRow('Created At', listingDetails!['created_at']),
                buildDetailRow('Taken At', listingDetails!['taken_at'] ?? 'N/A'),
                buildDetailRow('Ended At', listingDetails!['ended_at'] ?? 'N/A'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        '$label: ${value ?? 'Not provided'}',
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  Widget buildSkillsSection(List<dynamic> skills) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Skills Required:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            children: skills.map<Widget>((skill) {
              return Chip(
                label: Text(skill),
                backgroundColor: Colors.deepPurple[100],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
``