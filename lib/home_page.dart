import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'filter_dialog.dart';
import 'listing_detail_page.dart';
import 'create_listing_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  Set<String> selectedSkills = {};
  final _storage = FlutterSecureStorage();
  String userRole = '';
  List<Map<String, dynamic>> _allSkills = [];

  @override
  void initState() {
    super.initState();
    _fetchSkills();
    _fetchUserRole();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _fetchSkills() async {
    final Uri apiUrl = Uri.parse('http://10.0.2.2:8000/api/accounts/skills/');
    try {
      final response = await http.get(apiUrl);
      if (response.statusCode == 200) {
        final List<dynamic> skillsData = json.decode(response.body) as List;
        setState(() {
          _allSkills = skillsData.cast<Map<String, dynamic>>();
        });
      } else {
        throw Exception('Failed to load skills');
      }
    } catch (e) {
      // Handle errors
    }
  }

  Future<void> _fetchUserRole() async {
    try {
      String? role = await _storage.read(key: 'role');
      setState(() {
        userRole = role ?? '';
      });
    } catch (e) {
      // Handle errors
    }
  }

  Future<List<Map<String, dynamic>>> fetchOpenListings() async {
    var queryParameters = {
      if (_searchController.text.isNotEmpty) 'search': _searchController.text,
      if (_minPriceController.text.isNotEmpty) 'min_price': _minPriceController.text,
      if (_maxPriceController.text.isNotEmpty) 'max_price': _maxPriceController.text,
      if (selectedSkills.isNotEmpty) 'skills': selectedSkills.join(','),
    };

    final uri = Uri.http('10.0.2.2:8000', '/api/listings/open/', queryParameters);
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to load listings with status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load listings: $e');
    }
  }

  void _showFilterDialog() async {
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (BuildContext context) {
        return FilterDialog(
          selectedSkills: selectedSkills,
          allSkills: _allSkills,
          minPriceController: _minPriceController,
          maxPriceController: _maxPriceController,
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedSkills = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildSearchBar(),
        backgroundColor: Colors.deepPurple,
        elevation: 4.0,
        actions: _buildAppBarActions(),
      ),
      body: _buildBody(),
    );
  }

  List<Widget> _buildAppBarActions() {
    List<Widget> actions = [
      IconButton(
        icon: Icon(Icons.filter_list),
        onPressed: _showFilterDialog,
      ),
    ];
    if (userRole == 'client') {
      actions.add(IconButton(
        icon: Icon(Icons.add),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => CreateListingPage()));
        },
      ));
    }
    return actions;
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchOpenListings(),
        builder: _buildListView,
      ),
    );
  }

  Widget _buildListView(BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    } else if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${snapshot.error}'),
            ElevatedButton(
              child: Text('Retry'),
              onPressed: () => setState(() {}),
            ),
          ],
        ),
      );
    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return Center(child: Text('No listings found.'));
    } else {
      return ListView.separated(
        itemCount: snapshot.data!.length,
        separatorBuilder: (context, index) => Divider(color: Colors.grey),
        itemBuilder: (context, index) {
          Map<String, dynamic> listing = snapshot.data![index];
          return Card(
            elevation: 2.0,
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.deepPurple,
                child: Icon(Icons.list_alt, color: Colors.white),
              ),
              title: Text(
                listing['title'],
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
              subtitle: Text(
                listing['description'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ListingDetailPage(slug: listing['slug'])),
                );
              },
            ),
          );
        },
      );
    }
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search listings...',
        hintStyle: TextStyle(color: Colors.white),
        border: InputBorder.none,
      ),
      style: TextStyle(color: Colors.white),
      onSubmitted: (value) {
        if (this.mounted) {
          setState(() {});
        }
      },
    );
  }
}
