import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'widgets/get_food_flow.dart'; // Assuming your showGetBasketFlow lives here

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
                final donorId = foodData['userId'];
                final availableQuantity = foodData['quantity'] ?? 0;

                return FirebaseFirestore.instance
                    .collection('users')
                    .doc(donorId)
                    .get()
                    .then((donorDoc) {
                      final donorData = donorDoc.data();
                      final donorName = donorData?['name'] ?? 'Unknown';

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
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Center(child: Text('Please log in.'));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios),
                      onPressed:
                          () =>
                              Navigator.pushReplacementNamed(context, '/home'),
                    ),
                  ),
                  Text(
                    "G2G",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            ),

            // "My Basket" label
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 10),
              child: Row(
                children: [
                  Image.asset('assets/Bag.png', width: 24, height: 24),
                  SizedBox(width: 10),
                  Text(
                    "My Basket",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Basket items
            Expanded(
              child:
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : basketItems.isEmpty
                      ? Center(child: Text('Your basket is empty.'))
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
                                    color: Colors.teal,
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
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    color: Colors.red,
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  onDismissed: (direction) {
                                    FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(userId)
                                        .collection('basket')
                                        .doc(foodId)
                                        .delete();
                                    setState(() {
                                      isChecked.removeAt(index);
                                      _fetchBasketData();
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Item removed from basket',
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: containerColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: itemChecked,
                                          onChanged:
                                              canToggle
                                                  ? (value) {
                                                    setState(() {
                                                      isChecked[index] = value!;
                                                    });
                                                  }
                                                  : null,
                                          activeColor: Colors.green,
                                          checkColor: Colors.white,
                                        ),
                                        foodData['imageUrl'] != null
                                            ? Container(
                                              height: 80,
                                              width: 80,
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                  image: NetworkImage(
                                                    foodData['imageUrl'],
                                                  ),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            )
                                            : Icon(Icons.fastfood, size: 80),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                foodData['name'] ?? 'No Name',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                isUnavailable
                                                    ? 'Unavailable'
                                                    : 'Available: $availableQuantity',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      isUnavailable
                                                          ? Colors.red
                                                          : Colors.black,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Location: ${foodData['location'] ?? 'N/A'}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              if (!isUnavailable)
                                                Align(
                                                  alignment:
                                                      Alignment.bottomRight,
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[200],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            30,
                                                          ),
                                                      // boxShadow: [
                                                      //   BoxShadow(
                                                      //     color: Colors.black12,
                                                      //     blurRadius: 4,
                                                      //     offset: Offset(0, 2),
                                                      //   ),
                                                      // ],
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        InkWell(
                                                          onTap: () {
                                                            if (item['quantity'] >
                                                                1) {
                                                              setState(() {
                                                                item['quantity']--;
                                                              });
                                                            }
                                                          },
                                                          child: Icon(
                                                            Icons
                                                                .remove_circle_outline,
                                                            color: Colors.teal,
                                                            size: 24,
                                                          ),
                                                        ),
                                                        SizedBox(width: 10),
                                                        Text(
                                                          '${item['quantity']}',
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        SizedBox(width: 10),
                                                        InkWell(
                                                          onTap: () {
                                                            if (item['quantity'] <
                                                                availableQuantity) {
                                                              setState(() {
                                                                item['quantity']++;
                                                              });
                                                            }
                                                          },
                                                          child: Icon(
                                                            Icons
                                                                .add_circle_outline,
                                                            color: Colors.teal,
                                                            size: 24,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
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
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 100,
                child: ElevatedButton(
                  onPressed: _handleGet,
                  child: Text("GET"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
