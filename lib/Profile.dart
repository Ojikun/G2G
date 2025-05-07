import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'EditProfile.dart';
import 'History.dart';
import 'Food.dart';
import 'widgets/full_screen_image.dart';
import 'Chat.dart';
import 'Settings.dart';
import 'Badges.dart';
import 'Homepage.dart';

class ProfileScreen extends StatefulWidget {
  final String? otherUserId;
  const ProfileScreen({Key? key, this.otherUserId}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final User? currentUser;
  late final bool isCurrentUser;
  String fullName = '';
  String email = '';
  String? profileImageUrl;
  Future<List<Map<String, dynamic>>> _fetchRecentHistory() async {
    final allItems = <Map<String, dynamic>>[];

    // Fetch gives
    final givesSnapshot =
        await FirebaseFirestore.instance
            .collection('donations')
            .where('userId', isEqualTo: currentUser!.uid)
            .orderBy('timestamp', descending: true)
            .limit(2)
            .get();

    // Fetch gets
    final getsSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('gets')
            .orderBy('timestamp', descending: true)
            .limit(2)
            .get();

    // Fetch trades
    final tradesSnapshot =
        await FirebaseFirestore.instance
            .collection('trades')
            .where('uid', isEqualTo: currentUser!.uid)
            .orderBy('timestamp', descending: true)
            .limit(2)
            .get();

    // Add gives
    for (var doc in givesSnapshot.docs) {
      final data = doc.data();
      allItems.add({...data, 'type': 'Given', 'itemId': doc.id});
    }

    // Add gets
    for (var doc in getsSnapshot.docs) {
      final data = doc.data();
      allItems.add({...data, 'type': 'Received', 'itemId': data['foodId']});
    }

    // Add trades
    for (var doc in tradesSnapshot.docs) {
      final data = doc.data();
      allItems.add({...data, 'type': 'Traded', 'itemId': doc.id});
    }

    // Sort by timestamp
    allItems.sort((a, b) {
      final aTime = (a['timestamp'] as Timestamp).toDate();
      final bTime = (b['timestamp'] as Timestamp).toDate();
      return bTime.compareTo(aTime);
    });

    // Return only the 2 most recent items
    return allItems.take(2).toList();
  }

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    isCurrentUser =
        widget.otherUserId == null || widget.otherUserId == currentUser?.uid;
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    if (!mounted) return;

    final userId = widget.otherUserId ?? currentUser?.uid;
    if (userId == null) return;

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (!mounted) return;

      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          fullName = data?['name'] ?? 'No Name';
          email = data?['email'] ?? 'No Email';
          profileImageUrl = data?['profileImage'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please log in to view profile',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchUserDetails,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildProfileHeader(),
                  const SizedBox(height: 20),
                  _buildLatestBadgeSection(),
                  const SizedBox(height: 16),
                  _buildHistorySection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen()),
            );
          }
        },
      ),
      title: const Text(
        'Profile',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      backgroundColor: const Color(0xff238855),
      elevation: 0,
      actions: [
        if (isCurrentUser)
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SettingsScreen()),
                ),
          ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        _buildProfileImage(),
        const SizedBox(height: 16),
        Text(
          fullName.isNotEmpty ? fullName : email,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        if (email.isNotEmpty && fullName.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 16),
        _buildActionButton(),
      ],
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: () {
        if (profileImageUrl?.isNotEmpty ?? false) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullScreenImageView(imageUrl: profileImageUrl!),
            ),
          );
        }
      },
      child: Hero(
        tag: 'profileImage',
        child: CircleAvatar(
          radius: 50,
          backgroundColor: const Color(0xff238855),
          backgroundImage:
              profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
          child:
              profileImageUrl == null
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: 200,
      child: ElevatedButton(
        onPressed: () async {
          if (isCurrentUser) {
            final updated = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            );
            if (updated ?? false) _fetchUserDetails();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => ChatScreen(
                      personName: fullName,
                      currentUserId: currentUser!.uid,
                      otherUserId: widget.otherUserId!,
                      profileImageUrl: profileImageUrl,
                    ),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xfffd8536),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          isCurrentUser ? "EDIT PROFILE" : "MESSAGE",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLatestBadgeSection() {
    return _buildSection(
      title: "Latest Badge",
      onSeeAll:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BadgesScreen(userId: currentUser!.uid),
            ),
          ),
      child: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser!.uid)
                .collection('badges')
                .orderBy('earnedAt', descending: true)
                .limit(1)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final badges = snapshot.data!.docs;
          if (badges.isEmpty) {
            return const _InfoCard(
              showArrow: true,
              index: 0,
              isBadge: true,
              label: 'No badges yet',
            );
          }

          final badgeData = badges.first.data() as Map<String, dynamic>;
          return StreamBuilder<DocumentSnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('badges')
                    .doc(badgeData['badgeId'])
                    .snapshots(),
            builder: (context, badgeSnapshot) {
              if (!badgeSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final badge = badgeSnapshot.data!.data() as Map<String, dynamic>?;
              if (badge == null) {
                return const _InfoCard(
                  showArrow: true,
                  index: 0,
                  isBadge: true,
                  label: 'Badge not found',
                );
              }

              return _InfoCard(
                showArrow: true,
                index: badge['index'] ?? 0,
                isBadge: true,
                label: badge['badgeName'] ?? 'Unknown Badge',
                imageUrl: badge['badgeUrl'], // Add this line
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHistorySection() {
    return _buildSection(
      title: "History",
      onSeeAll:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          ),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchRecentHistory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final recentItems = snapshot.data!;

          if (recentItems.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No history yet'),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentItems.length,
            itemBuilder: (context, index) {
              final item = recentItems[index];
              return Card(
                color: const Color(0xfff8f8f8),
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        item['imageUrl'] != null
                            ? Image.network(
                              item['imageUrl'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                            : Container(
                              width: 50,
                              height: 50,
                              color: Colors.white,
                              child: const Icon(Icons.fastfood),
                            ),
                  ),
                  title: Text(
                    item['name'] ?? item['foodName'] ?? 'Unknown Item',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${item['type']} • ${_formatTimestamp(item['timestamp'])}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    if (item['itemId'] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FoodScreen(foodId: item['itemId']),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required VoidCallback onSeeAll,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: onSeeAll,
              child: const Text(
                "See All",
                style: TextStyle(
                  color: Color(0xff238855),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        child,
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final bool showArrow;
  final int index;
  final bool isBadge;
  final String label;
  final String? imageUrl; // Add this field

  const _InfoCard({
    this.showArrow = false,
    required this.index,
    required this.isBadge,
    required this.label,
    this.imageUrl, // Add this parameter
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image:
                  imageUrl != null
                      ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      )
                      : DecorationImage(
                        image: AssetImage(
                          isBadge
                              ? 'assets/badge${index + 1}.png'
                              : 'assets/food${index + 1}.png',
                        ),
                        fit: BoxFit.cover,
                      ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          //
        ],
      ),
    );
  }
}

String _formatTimestamp(Timestamp? timestamp) {
  if (timestamp == null) return '';

  final date = timestamp.toDate();
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';

  return DateFormat('MMM d').format(date);
}
