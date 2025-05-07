import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
    Key? key,
  }) : super(key: key);

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  Widget coloredIcon(
    String assetPath,
    bool isSelected,
    double width,
    double height,
  ) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        isSelected ? Color(0xff238855) : Colors.grey,
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
            // Basket icon with consistent size
            coloredIcon('assets/basketicon.png', isSelected, width, height),
            if (basketCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Color(0xfffd8536),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$basketCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
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

  Widget messageIconWithBadge(bool isSelected, double width, double height) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('chats')
              .where('participants', arrayContains: currentUser.uid)
              .snapshots(),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final readStatus =
                data['readStatus'] as Map<String, dynamic>? ?? {};
            if (!(readStatus[currentUser.uid] ?? true)) {
              unreadCount++;
            }
          }
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            coloredIcon('assets/chaticon.png', isSelected, width, height),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xfffd8536),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
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

  Widget notificationIconWithBadge(
    bool isSelected,
    double width,
    double height,
  ) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('notifications')
              .where('isRead', isEqualTo: false)
              .snapshots(),
      builder: (context, snapshot) {
        int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return Stack(
          alignment: Alignment.center,
          children: [
            coloredIcon('assets/notificon.png', isSelected, width, height),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xfffd8536),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        16,
      ), // Rounded corners for the container
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100], // Semi-transparent background
          borderRadius: BorderRadius.circular(16), // Rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // Shadow color
              blurRadius: 9.5, // Blur radius
              offset: Offset(0, 4), // Shadow offset
            ),
          ],
        ),
        height: 70, // Increased height to accommodate labels
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Home Icon
            GestureDetector(
              onTap: () => widget.onItemTapped(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  coloredIcon(
                    'assets/homeicon.png',
                    widget.selectedIndex == 0,
                    40,
                    40,
                  ),
                  // SizedBox(height: 1),
                  Text(
                    'Home',
                    style: TextStyle(
                      color:
                          widget.selectedIndex == 0
                              ? Color(0xff238855)
                              : Colors.grey,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),

            // Basket Icon
            GestureDetector(
              onTap: () => widget.onItemTapped(1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  basketIconWithBadge(widget.selectedIndex == 1, 40, 40),
                  // SizedBox(height: 1),
                  Text(
                    'Basket',
                    style: TextStyle(
                      color:
                          widget.selectedIndex == 1
                              ? Color(0xff238855)
                              : Colors.grey,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),

            // Messages Icon
            GestureDetector(
              onTap: () => widget.onItemTapped(2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  messageIconWithBadge(widget.selectedIndex == 2, 40, 40),
                  Text(
                    'Messages',
                    style: TextStyle(
                      color:
                          widget.selectedIndex == 2
                              ? const Color(0xff238855)
                              : Colors.grey,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),

            // Notifications Icon
            GestureDetector(
              onTap: () => widget.onItemTapped(3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  notificationIconWithBadge(widget.selectedIndex == 3, 40, 40),
                  Text(
                    'Notifs',
                    style: TextStyle(
                      color:
                          widget.selectedIndex == 3
                              ? const Color(0xff238855)
                              : Colors.grey,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),

            // Account Icon
            GestureDetector(
              onTap: () => widget.onItemTapped(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  coloredIcon(
                    'assets/accicon.png',
                    widget.selectedIndex == 4,
                    40,
                    40,
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Account',
                    style: TextStyle(
                      color:
                          widget.selectedIndex == 4
                              ? Color(0xff238855)
                              : Colors.grey,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
