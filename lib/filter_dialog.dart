import 'package:flutter/material.dart';

class FilterDialog extends StatefulWidget {
  final Set<String> selectedSkills;
  final List<Map<String, dynamic>> allSkills;
  final TextEditingController minPriceController;
  final TextEditingController maxPriceController;

  FilterDialog({
    required this.selectedSkills,
    required this.allSkills,
    required this.minPriceController,
    required this.maxPriceController,
  });

  @override
  _FilterDialogState createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late Set<String> selectedSkills;
  String currentSearch = '';

  @override
  void initState() {
    super.initState();
    selectedSkills = Set<String>.from(widget.selectedSkills);
  }

  @override
Widget build(BuildContext context) {
  List<Map<String, dynamic>> filteredSkills = widget.allSkills
      .where((skill) => skill['name'].toLowerCase().contains(currentSearch.toLowerCase()))
      .toList();

  return AlertDialog(
    backgroundColor: Colors.white, // Set the AlertDialog background to white
    title: Text('Filter Listings', style: TextStyle(color: Colors.black)), // Ensure text color contrasts with background
    content: Container(
      height: MediaQuery.of(context).size.height * 0.4,
      width: double.maxFinite,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: widget.minPriceController,
              decoration: InputDecoration(
                labelText: 'Minimum Price',
                labelStyle: TextStyle(color: Colors.grey), // Color for the label
                enabledBorder: OutlineInputBorder( // Normal border
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder( // Border when TextField is focused
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.black), // Text color
            ),
            TextField(
              controller: widget.maxPriceController,
              decoration: InputDecoration(
                labelText: 'Maximum Price',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.black),
            ),
            TextField(
              onChanged: (value) {
                setState(() {
                  currentSearch = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Search Skill',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              style: TextStyle(color: Colors.black),
            ),
            ...filteredSkills.map((skill) {
              return CheckboxListTile(
                title: Text(skill['name'], style: TextStyle(color: Colors.black)), // Text color
                value: selectedSkills.contains(skill['name']),
                onChanged: (bool? value) {
                  setState(() {
                    if (value ?? false) {
                      selectedSkills.add(skill['name']);
                    } else {
                      selectedSkills.remove(skill['name']);
                    }
                  });
                },
                checkColor: Colors.white, // color of tick Mark
                activeColor: Colors.blue, // color of the checkbox
              );
            }).toList(),
          ],
        ),
      ),
    ),
    actions: <Widget>[
      ElevatedButton(
        child: Text('Apply', style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.of(context).pop(selectedSkills);
        },
        style: ElevatedButton.styleFrom(
          primary: Colors.blue, // Button color
          onPrimary: Colors.white, // Text color
        ),
      ),
    ],
  );
}

}
