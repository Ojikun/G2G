import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GiveFoodPage(),
    );
  }
}

class DateTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;

    text = text.replaceAll(RegExp(r'[^0-9]'), '');

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(text[i]);
    }

    final formatted = buffer.toString().substring(0, buffer.length > 10 ? 10 : buffer.length);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class GiveFoodPage extends StatefulWidget {
  @override
  _GiveFoodPageState createState() => _GiveFoodPageState();
}

class _GiveFoodPageState extends State<GiveFoodPage> {
  int _selectedIndex = 1;

  final List<String> foodTypes = ['Fruits', 'Vegetables', 'Canned Goods', 'Others'];
  String? selectedFoodType;
  int quantity = 0;
  String selectedOption = '';

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget coloredIcon(String assetPath, bool isSelected, double width, double height) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        isSelected ? Colors.teal : Colors.black,
        BlendMode.srcIn,
      ),
      child: Image.asset(
        assetPath,
        width: width,
        height: height,
      ),
    );
  }

  InputDecoration customInputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(50),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.teal),
        borderRadius: BorderRadius.circular(50),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.grey[300],
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.black,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: coloredIcon('assets/Home.png', _selectedIndex == 0, 25, 25),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: coloredIcon('assets/Give.png', _selectedIndex == 1, 40, 40),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: coloredIcon('assets/Get.png', _selectedIndex == 2, 40, 40),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: coloredIcon('assets/Trade.png', _selectedIndex == 3, 40, 40),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: coloredIcon('assets/Bag.png', _selectedIndex == 4, 30, 30),
            label: '',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
          children: [
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
            const SizedBox(height: 20),
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: const Center(child: Icon(Icons.add_a_photo, size: 60, color: Colors.grey)),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedFoodType,
              hint: Text('Food Type'),
              items: foodTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedFoodType = value;
                });
              },
              decoration: customInputDecoration("", "Food Type"),
            ),
            const SizedBox(height: 15),
            TextField(
              decoration: customInputDecoration("Name", "Food Name Here"),
            ),
            const SizedBox(height: 15),
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [DateTextFormatter()],
              decoration: customInputDecoration("Expiry", "MM/DD/YYYY"),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(50),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Quantity'),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          setState(() {
                            if (quantity > 0) quantity--;
                          });
                        },
                      ),
                      Text(
                        quantity.toString(),
                        style: TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline),
                        onPressed: () {
                          setState(() {
                            quantity++;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              decoration: customInputDecoration("Note", "Additional details here"),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedOption = 'DROP-OFF';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedOption == 'DROP-OFF' ? Colors.teal : Colors.white,
                      foregroundColor: selectedOption == 'DROP-OFF' ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.teal),
                    ),
                    child: const Text("DROP-OFF"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedOption = 'PICKUP';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedOption == 'PICKUP' ? Colors.teal : Colors.white,
                      foregroundColor: selectedOption == 'PICKUP' ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.teal),
                    ),
                    child: const Text("PICKUP"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            TextField(
              decoration: customInputDecoration("Location", "Location Here"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print("Food Type: $selectedFoodType");
                print("Quantity: $quantity");
                print("Option: $selectedOption");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("GIVE", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
