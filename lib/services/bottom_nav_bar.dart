import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  BottomNavBar({required this.selectedIndex, required this.onItemTapped});

  Widget coloredIcon(
    String assetPath,
    bool isSelected,
    double width,
    double height,
  ) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        isSelected ? Color(0xfffcfaf8) : Color(0xff130f1e),
        BlendMode.srcIn,
      ),
      child: Image.asset(assetPath, width: width, height: height),
    );
  }

  Widget basketIconWithBadge(bool isSelected, double width, double height) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .collection('basket')
              .snapshots(),
      builder: (context, snapshot) {
        int basketCount = 0;
        if (snapshot.hasData) {
          basketCount = snapshot.data!.docs.length;
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            coloredIcon('assets/Bag.png', isSelected, width, height),
            if (basketCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$basketCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Color(0xffffc533),
      selectedItemColor: Color(0xfffcfaf8),
      unselectedItemColor: Color(0xff130f1e),
      showSelectedLabels: false,
      showUnselectedLabels: false,
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      items: [
        BottomNavigationBarItem(
          icon: coloredIcon('assets/Home.png', selectedIndex == 0, 25, 25),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: coloredIcon('assets/Give.png', selectedIndex == 1, 40, 40),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: coloredIcon('assets/Get.png', selectedIndex == 2, 40, 40),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: coloredIcon('assets/Trade.png', selectedIndex == 3, 40, 40),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: basketIconWithBadge(
            selectedIndex == 4,
            33,
            33,
          ), // Basket icon with badge
          label: '',
        ),
      ],
    );
  }
}
