import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChatDetailPage extends StatefulWidget {
  final Map<String, dynamic> chat;

  ChatDetailPage({required this.chat});

  @override
  _ChatDetailPageState createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final storage = FlutterSecureStorage();
  final TextEditingController _messageController = TextEditingController();
  String userId = '';

  @override
  void initState() {
    super.initState();
    getUserId();
    fetchMessages();
  }

  void getUserId() async {
    userId = await storage.read(key: 'userId') ?? '0';
  }

  Future<void> fetchMessages() async {
    String? token = await storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/chats/${widget.chat['id']}/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      setState(() {
        widget.chat['messages'] = json.decode(response.body)['messages'];
      });
    }
  }

  Future<void> sendMessage() async {
    String? token = await storage.read(key: 'token');
    if (_messageController.text.isEmpty) return;

    final payload = {
      'content': _messageController.text,
      'chat': widget.chat['id'],
      'author': int.parse(userId),
    };

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/chats/${widget.chat['id']}/send/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(payload),
    );

    if (response.statusCode == 201) {
      setState(() {
        widget.chat['messages'].add(json.decode(response.body));
        _messageController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.chat['participant_usernames'].join(', ')}'),
        backgroundColor: Colors.purple[300],
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.purple[50],
              ),
              child: ListView.builder(
                itemCount: widget.chat['messages'].length,
                itemBuilder: (context, index) {
                  final message = widget.chat['messages'][index];
                  final bool isMe = message['author'].toString() == userId;
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.all(8.0),
                      margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.purple[200] : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        message['content'],
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      labelText: 'Type your message',
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.purple[100],
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.purple[300],
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
