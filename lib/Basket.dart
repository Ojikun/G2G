import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'widgets/get_food_flow.dart'; // Assuming your showGetBasketFlow lives here
import 'Homepage.dart'; // Assuming your HomeScreen lives here

class BasketScreen extends StatefulWidget {
  @override
  _BasketScreenState createState() => _BasketScreenState();
}

class _BasketScreenState extends State<BasketScreen> {
  List<bool> isChecked = [];
  Map<String, List<Map<String, dynamic>>> groupedItems = {};
  List<QueryDocumentSnapshot> basketItems = [];
  bool isLoading = true;

  int get checkedCount => isChecked.where((item) => item).length;
  final userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    if (userId != null) {
      _fetchBasketData();
    }
  }

  void _fetchBasketData() async {
    setState(() {
      isLoading = true;
    });

    final basketSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('basket')
            .get();

    final items = basketSnapshot.docs;
    basketItems = items;

    if (items.isEmpty) {
      setState(() {
        groupedItems.clear();
        isChecked = [];
        isLoading = false;
      });
      return;
    }

    isChecked = List.filled(items.length, false);

    Map<String, List<Map<String, dynamic>>> tempGroupedItems = {};
    List<Future<void>> futures = [];

    for (int i = 0; i < items.length; i++) {
      final basketItem = items[i];
      final foodId = basketItem.id;
      final basketQuantity = basketItem['quantity'] ?? 0;

      futures.add(
        FirebaseFirestore.instance
            .collection('donations')
            .doc(foodId)
            .get()
            .then((foodDoc) {
              if (foodDoc.exists) {
                final foodData = foodDoc.data() as Map<String, dynamic>;
                final donorName =
                    foodData['username'] ?? 'Unknown'; // Use username field
                final availableQuantity = foodData['quantity'] ?? 0;

                if (!tempGroupedItems.containsKey(donorName)) {
                  tempGroupedItems[donorName] = [];
                }

                tempGroupedItems[donorName]!.add({
                  'foodId': foodId,
                  'foodData': foodData,
                  'quantity': basketQuantity,
                  'availableQuantity': availableQuantity,
                  'index': i,
                });
              }
            }),
      );
    }

    await Future.wait(futures);

    setState(() {
      groupedItems = tempGroupedItems;
      isLoading = false;
    });
  }

  void _handleGet() {
    final selectedItems = <GetFoodItem>[];

    for (var donorItems in groupedItems.values) {
      for (var item in donorItems) {
        final index = item['index'] as int;
        final isSelected = isChecked[index];
        final isUnavailable = item['availableQuantity'] == 0;

        if (isSelected && !isUnavailable) {
          final foodData = item['foodData'] as Map<String, dynamic>;
          selectedItems.add(
            GetFoodItem(
              foodId: item['foodId'],
              foodName: foodData['name'] ?? 'Unnamed Food',
              location: foodData['location'] ?? 'Unknown',
              quantity: item['quantity'],
              imageUrl: foodData['imageUrl'] ?? '',
            ),
          );
        }
      }
    }

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No available items selected!')));
      return;
    }

    showGetBasketFlow(context: context, items: selectedItems);

    // Refresh the basket data after the flow completes
    _fetchBasketData();
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Center(child: Text('Please log in.'));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context); // Go back to the previous screen
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
                (route) => false, // Remove all previous routes
              );
            }
          },
        ),
        title: Text(
          'My Basket',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Color(0xff238855), // Updated AppBar color
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child:
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : basketItems.isEmpty
                      ? Center(
                        child: Text(
                          'Your basket is empty',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                      )
                      : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: groupedItems.keys.length,
                        itemBuilder: (context, donorIndex) {
                          final donorName =
                              groupedItems.keys.toList()[donorIndex];
                          final items = groupedItems[donorName]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 8,
                                  top: 16,
                                ),
                                child: Text(
                                  'From $donorName',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xfffd8536),
                                  ),
                                ),
                              ),
                              ...items.map((item) {
                                final foodData =
                                    item['foodData'] as Map<String, dynamic>;
                                final availableQuantity =
                                    item['availableQuantity'];
                                final index = item['index'];
                                final foodId = item['foodId'];
                                final isUnavailable = availableQuantity == 0;
                                final itemChecked = isChecked[index];
                                final canToggle =
                                    !isUnavailable &&
                                    (itemChecked || checkedCount < 3);

                                final containerColor =
                                    isUnavailable
                                        ? Colors.grey[400]
                                        : (canToggle
                                            ? Colors.grey[200]
                                            : Colors.grey[400]);

                                return Dismissible(
                                  key: Key(foodId),
                                  direction: DismissDirection.endToStart,
                                  background: SizedBox.expand(
                                    // Ensures the red background matches the item's height
                                    child: Container(
                                      alignment: Alignment.centerRight,
                                      padding: EdgeInsets.only(right: 20),
                                      margin: EdgeInsets.only(bottom: 10),

                                      color: Color(0xfffd8536),
                                      child: Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                  onDismissed: (direction) async {
                                    // Remove the item from Firestore
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(userId)
                                        .collection('basket')
                                        .doc(foodId)
                                        .delete();

                                    // Refresh the basket data
                                    _fetchBasketData();

                                    // Show a confirmation message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Item removed from basket',
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: containerColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.all(3),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Checkbox, Image, and Texts (Food Name, Availability, Location)
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .center, // Center items vertically
                                          children: [
                                            // Checkbox
                                            Checkbox(
                                              value: itemChecked,
                                              onChanged:
                                                  canToggle
                                                      ? (value) {
                                                        setState(() {
                                                          isChecked[index] =
                                                              value!;
                                                        });
                                                      }
                                                      : null,
                                              activeColor: Color(0xff238855),
                                              checkColor: Colors.white,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap, // Reduce checkbox size
                                            ),
                                            // Image
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child:
                                                  foodData['imageUrl'] != null
                                                      ? Image.network(
                                                        foodData['imageUrl'],
                                                        width:
                                                            80, // Increased width
                                                        height:
                                                            80, // Increased height
                                                        fit: BoxFit.cover,
                                                      )
                                                      : Container(
                                                        width:
                                                            80, // Increased width
                                                        height:
                                                            80, // Increased height
                                                        color: Colors.grey[200],
                                                        child: Icon(
                                                          Icons.fastfood,
                                                          color: Color(
                                                            0xfffd8536,
                                                          ),
                                                          size:
                                                              40, // Adjusted icon size
                                                        ),
                                                      ),
                                            ),
                                            SizedBox(
                                              width: 8,
                                            ), // Reduced space between the image and the text
                                            // Food Name, Availability, Location, and Quantity
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    height: 8,
                                                  ), // Space between image and text
                                                  // Food Name
                                                  Text(
                                                    foodData['name'] ??
                                                        'No Name',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  // Availability
                                                  Text(
                                                    isUnavailable
                                                        ? 'Unavailable'
                                                        : 'Available',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          isUnavailable
                                                              ? Colors.red
                                                              : Colors.black,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  // Location
                                                  Text(
                                                    'Location: ${foodData['location'] ?? 'N/A'}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  // Quantity
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        'Quantity:',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Row(
                                                        children: [
                                                          // Decrement Button
                                                          IconButton(
                                                            icon: Icon(
                                                              Icons
                                                                  .remove_circle_outline,
                                                              size: 20,
                                                            ),
                                                            padding:
                                                                EdgeInsets.zero,
                                                            constraints:
                                                                BoxConstraints(),
                                                            color:
                                                                item['quantity'] >
                                                                        1
                                                                    ? Color(
                                                                      0xfffd8536,
                                                                    )
                                                                    : Colors
                                                                        .grey,
                                                            onPressed:
                                                                item['quantity'] >
                                                                        1
                                                                    ? () async {
                                                                      setState(
                                                                        () {
                                                                          item['quantity']--;
                                                                        },
                                                                      );

                                                                      // Update the quantity in Firestore
                                                                      await FirebaseFirestore
                                                                          .instance
                                                                          .collection(
                                                                            'users',
                                                                          )
                                                                          .doc(
                                                                            userId,
                                                                          )
                                                                          .collection(
                                                                            'basket',
                                                                          )
                                                                          .doc(
                                                                            item['foodId'],
                                                                          )
                                                                          .update({
                                                                            'quantity':
                                                                                item['quantity'],
                                                                          });
                                                                    }
                                                                    : null, // Disable button if quantity is 1
                                                          ),
                                                          Text(
                                                            '${item['quantity']}',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          // Increment Button
                                                          IconButton(
                                                            icon: Icon(
                                                              Icons
                                                                  .add_circle_outline,
                                                              size: 20,
                                                            ),
                                                            padding:
                                                                EdgeInsets.zero,
                                                            constraints:
                                                                BoxConstraints(),
                                                            color:
                                                                item['quantity'] <
                                                                        item['availableQuantity']
                                                                    ? Color(
                                                                      0xfffd8536,
                                                                    )
                                                                    : Colors
                                                                        .grey,
                                                            onPressed:
                                                                item['quantity'] <
                                                                        item['availableQuantity']
                                                                    ? () async {
                                                                      setState(
                                                                        () {
                                                                          item['quantity']++;
                                                                        },
                                                                      );

                                                                      // Update the quantity in Firestore
                                                                      await FirebaseFirestore
                                                                          .instance
                                                                          .collection(
                                                                            'users',
                                                                          )
                                                                          .doc(
                                                                            userId,
                                                                          )
                                                                          .collection(
                                                                            'basket',
                                                                          )
                                                                          .doc(
                                                                            item['foodId'],
                                                                          )
                                                                          .update({
                                                                            'quantity':
                                                                                item['quantity'],
                                                                          });
                                                                    }
                                                                    : null, // Disable button if quantity reaches availableQuantity
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          );
                        },
                      ),
            ),

            // GET button
            Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(context).viewInsets.bottom > 0
                        ? MediaQuery.of(context).viewInsets.bottom +
                            16 // Adjust above the overlay
                        : MediaQuery.of(context).padding.bottom +
                            16, // Adjust above the navigation bar
              ),
              child: Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 150, // Set a fixed width for the button
                  child: ElevatedButton(
                    onPressed: _handleGet, // Original functionality
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xfffd8536),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // Match the provided style
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14), // Match size
                    ),
                    child: Text(
                      "GET",
                      style: TextStyle(
                        color: Colors.white,
                      ), // Match the provided style
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
