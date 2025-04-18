import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'Food.dart';

class GetScreenPage extends StatefulWidget {
  @override
  _GetScreenPageState createState() => _GetScreenPageState();
}

class _GetScreenPageState extends State<GetScreenPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedField = 'All';

  final List<String> _filterFields = [
    'All',
    'name',
    'foodType',
    'location',
    'expiry',
    'username',
  ];

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
          child: Column(
            children: [
              // Top row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.person),
                  SizedBox(width: 42),
                  Text(
                    "G2G",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  SizedBox(width: 40),
                  Icon(Icons.mail),
                ],
              ),

              SizedBox(height: 20),

              // Search Row
              Row(
                children: [
                  // Search bar
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 10),

                  // Filter Icon
                  IconButton(
                    icon: Icon(Icons.filter_alt, color: Colors.teal),
                    onPressed: () {
                      _showFilterDropdown(context);
                    },
                  ),
                ],
              ),

              // Category Selection (below search box)
              if (_selectedField != 'All')
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Filter by: ${_getFilterText(_selectedField)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              SizedBox(height: 20),

              // Grid
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('donations')
                          .where('status', isEqualTo: 'available')
                          .where('userId', isNotEqualTo: currentUserId)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Something went wrong.'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No available donations.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      );
                    }

                    // Filter docs based on search query and selected field
                    final filteredDocs =
                        docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;

                          // If search query is empty — no filtering needed
                          if (_searchQuery.isEmpty) return true;

                          if (_selectedField == 'All') {
                            // Search in multiple fields
                            return (data['name']?.toString().toLowerCase() ??
                                        '')
                                    .contains(_searchQuery) ||
                                (data['foodType']?.toString().toLowerCase() ??
                                        '')
                                    .contains(_searchQuery) ||
                                (data['location']?.toString().toLowerCase() ??
                                        '')
                                    .contains(_searchQuery) ||
                                (data['expiry']?.toString().toLowerCase() ?? '')
                                    .contains(_searchQuery) ||
                                (data['username']?.toString().toLowerCase() ??
                                        '')
                                    .contains(_searchQuery);
                          } else {
                            // Search in selected field only
                            final fieldValue =
                                data[_selectedField]
                                    ?.toString()
                                    .toLowerCase() ??
                                '';
                            return fieldValue.contains(_searchQuery);
                          }
                        }).toList();

                    if (filteredDocs.isEmpty) {
                      return Center(
                        child: Text(
                          'No matching donations found.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      physics: BouncingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final imageUrl = data['imageUrl'] as String? ?? '';
                        final name = data['name'] as String? ?? 'No Name';

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FoodScreen(foodId: doc.id),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child:
                                      imageUrl.isNotEmpty
                                          ? Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          )
                                          : Icon(
                                            Icons.fastfood,
                                            size: 60,
                                            color: Colors.teal,
                                          ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  name,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to show the filter dropdown
  void _showFilterDropdown(BuildContext context) async {
    String selectedField =
        await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Select Filter'),
              content: SingleChildScrollView(
                child: Column(
                  children:
                      _filterFields.map((field) {
                        return ListTile(
                          title: Text(
                            field == 'All'
                                ? 'All Fields'
                                : field == 'name'
                                ? 'By Food'
                                : field == 'foodType'
                                ? 'By Food Type'
                                : field == 'location'
                                ? 'By Location'
                                : field == 'expiry'
                                ? 'By Expiration Date'
                                : 'By Donor',
                          ),
                          onTap: () {
                            Navigator.pop(context, field);
                          },
                        );
                      }).toList(),
                ),
              ),
            );
          },
        ) ??
        'All';

    setState(() {
      _selectedField = selectedField;
    });
  }

  // Function to map the selected field to the display text
  String _getFilterText(String field) {
    switch (field) {
      case 'name':
        return 'Food';
      case 'foodType':
        return 'Food Type';
      case 'location':
        return 'Location';
      case 'expiry':
        return 'Expiration Date';
      case 'username':
        return 'Donor';
      default:
        return 'Food';
    }
  }
}
