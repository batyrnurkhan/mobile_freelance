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
      title: Text('Filter Listings'),
      content: Container(
        height: MediaQuery.of(context).size.height * 0.4,
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: widget.minPriceController,
                decoration: InputDecoration(labelText: 'Minimum Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: widget.maxPriceController,
                decoration: InputDecoration(labelText: 'Maximum Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                onChanged: (value) {
                  setState(() {
                    currentSearch = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Search Skill',
                ),
              ),
              ...filteredSkills.map((skill) {
                return CheckboxListTile(
                  title: Text(skill['name']),
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
                );
              }).toList(),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          child: Text('Apply'),
          onPressed: () {
            Navigator.of(context).pop(selectedSkills);
          },
        ),
      ],
    );
  }
}
