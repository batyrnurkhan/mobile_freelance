import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReviewPage extends StatefulWidget {
  final String freelancerUsername;

  ReviewPage({required this.freelancerUsername});

  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final _formKey = GlobalKey<FormState>();
  double _rating = 0;
  String _review = '';

  Future<void> submitReview() async {
    var url = 'http://10.0.2.2:8000/api/accounts/reviews/create/${widget.freelancerUsername}'; // URL updated to use username
    var response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'rating': _rating,
        'text': _review,
      }),
    );

    if (response.statusCode == 201) {
      Navigator.pop(context); // Go back after successful submission
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Review submitted successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit review')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Write a Review')),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Rating (1-5)'),
                keyboardType: TextInputType.number,
                onSaved: (value) {
                  _rating = double.parse(value ?? '0');
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Review'),
                maxLines: 5,
                onSaved: (value) {
                  _review = value ?? '';
                },
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    submitReview();
                  }
                },
                child: Text('Submit Review'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
