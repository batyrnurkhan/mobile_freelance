import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'listing_detail_page.dart';
import 'home_page.dart';

class InProgressListingsPage extends StatefulWidget {
  @override
  _InProgressListingsPageState createState() => _InProgressListingsPageState();
}

class _InProgressListingsPageState extends State<InProgressListingsPage> {
  final storage = FlutterSecureStorage();
  List<dynamic> inProgressListings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchInProgressListings();
  }

  Future<void> fetchInProgressListings() async {
    String? token = await storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/listings/user-specific/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    setState(() {
      if (response.statusCode == 200) {
        inProgressListings = json.decode(response.body);
      }
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('In Progress Listings'),
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : inProgressListings.isEmpty
              ? _buildNoListingsView()
              : _buildListingsListView(),
    );
  }

  Widget _buildNoListingsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('YOU DON\'T HAVE TAKEN LISTINGS. CONTACT CLIENT OR GO TO HOME PAGE', textAlign: TextAlign.center),
          TextButton(
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage())),
            child: Text('Home Page', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildListingsListView() {
    return ListView.separated(
      itemCount: inProgressListings.length,
      separatorBuilder: (context, index) => Divider(color: Colors.grey),
      itemBuilder: (context, index) {
        var listing = inProgressListings[index];
        return Card(
          elevation: 2.0,
          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.list_alt, color: Colors.white),
            ),
            title: Text(listing['title'], style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            subtitle: Text('Status: ${listing['status']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600])),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ListingDetailPage(slug: listing['slug']))),
          ),
        );
      },
    );
  }
}
