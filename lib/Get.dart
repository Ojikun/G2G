import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

import 'Food.dart';
import 'Homepage.dart';

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
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
              (route) => false,
            );
          },
        ),
        title: Text(
          'Get Donations',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Color(0xff238855),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Row
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16,
              ),
              child: Row(
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
                      cursorColor: Color(
                        0xff238855,
                      ), // Set the cursor color directly on the TextField
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey,
                        ), // Updated icon color
                        suffixIcon: Row(
                          mainAxisSize:
                              MainAxisSize
                                  .min, // Ensure the row takes minimal space
                          children: [
                            // Clear (x) button
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Color(
                                    0xff238855,
                                  ), // Updated icon color
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              ),

                            // Filter icon
                            IconButton(
                              icon: Icon(Icons.tune, color: Color(0xfffd8536)),
                              onPressed: () {
                                _showFilterDropdown(context);
                              },
                            ),
                          ],
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Color(0xff238855),
                          ), // Updated border color when focused
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category Selection (below search box)
            if (_selectedField != 'All')
              Padding(
                padding: const EdgeInsets.only(left: 20.0, bottom: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Filter by: ${_getFilterText(_selectedField)}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            // Scrollable Grid
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
                          color: Color(0xfffd8536),
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
                          return (data['name']?.toString().toLowerCase() ?? '')
                                  .contains(_searchQuery) ||
                              (data['foodType']?.toString().toLowerCase() ?? '')
                                  .contains(_searchQuery) ||
                              (data['location']?.toString().toLowerCase() ?? '')
                                  .contains(_searchQuery) ||
                              (data['expiry']?.toString().toLowerCase() ?? '')
                                  .contains(_searchQuery) ||
                              (data['username']?.toString().toLowerCase() ?? '')
                                  .contains(_searchQuery);
                        } else {
                          // Search in selected field only
                          final fieldValue =
                              data[_selectedField]?.toString().toLowerCase() ??
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

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                    ), // Add horizontal margin
                    child: GridView.builder(
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
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey, // Border color
                                width: 0.5, // Border width
                              ),
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16.0),
                              child: Stack(
                                children: [
                                  // Background image
                                  Positioned.fill(
                                    child:
                                        imageUrl.isNotEmpty
                                            ? Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                            )
                                            : Container(
                                              color: Color(0xfffd8536),
                                              child: Center(
                                                child: Icon(
                                                  Icons.fastfood,
                                                  size: 60,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                  ),

                                  // Gradient overlay with text at the bottom
                                  Positioned(
                                    left: 0,
                                    bottom: 0,
                                    child: Container(
                                      height:
                                          50, // Adjust height for the gradient
                                      width:
                                          MediaQuery.of(context).size.width /
                                              2 -
                                          20, // Calculate width for each grid item
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors
                                                .transparent, // Start with transparent
                                            Colors.black.withOpacity(
                                              0.5,
                                            ), // End with black with opacity
                                          ],
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: Align(
                                          alignment: Alignment.bottomLeft,
                                          child: Text(
                                            name, // Use the food name
                                            style: TextStyle(
                                              color:
                                                  Colors
                                                      .white, // White text for contrast
                                              fontWeight: FontWeight.bold,
                                              fontSize:
                                                  14, // Adjust font size as needed
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
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
            return Theme(
              data: ThemeData.light().copyWith(
                dialogBackgroundColor:
                    Colors.white, // Set background color to white
              ),
              child: AlertDialog(
                title: Text(
                  'Select Filter',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xff238855), // Set title text color
                  ),
                ),
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
                              style: TextStyle(
                                color: Colors.black, // Set text color
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context, field);
                            },
                          );
                        }).toList(),
                  ),
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
