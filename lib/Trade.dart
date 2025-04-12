import 'package:flutter/material.dart';

void main() {
  runApp(TradeApp());
}

class TradeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trade UI',
      theme: ThemeData(primarySwatch: Colors.amber),
      home: TradeHomePage(),
    );
  }
}

class TradeHomePage extends StatefulWidget {
  @override
  _TradeHomePageState createState() => _TradeHomePageState();
}

class _TradeHomePageState extends State<TradeHomePage> {
  int _selectedIndex = 3;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "G2G",
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Create trade request',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildCard(hasImages: false),
          SizedBox(height: 16),
          _buildCard(hasImages: true),
          SizedBox(height: 16),
          _buildCard(hasImages: false),
        ],
      ),
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
    );
  }

  Widget _buildCard({bool hasImages = false}) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(Icons.person, color: Colors.white),
              ),
              SizedBox(width: 8),
              Text(
                'FoodieTrader23',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            hasImages
                ? "Offering freshly baked banana bread 🍌🍞 for trade!"
                : "Looking for homemade kimchi 🥬🔥, can offer organic eggs 🥚 in exchange!",
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          if (hasImages)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                3,
                    (index) => Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(8),
                  ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/bananabread.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                ),
              ),
            ),
          SizedBox(height: 8),
          Text(
            '2 hrs ago',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }


  Widget coloredIcon(String assetPath, bool isSelected, double width, double height) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      color: isSelected ? Colors.teal : Colors.black,
    );
  }
}
