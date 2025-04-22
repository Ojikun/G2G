import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const int kWeeklyLimit = 3;

Future<int> getRemainingWeeklyQuantity() async {
  final userId = FirebaseAuth.instance.currentUser!.uid;

  final gets =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('gets')
          .where(
            'timestamp',
            isGreaterThan: DateTime.now().subtract(Duration(days: 7)),
          )
          .get();

  int weeklyTotal = gets.docs.fold(
    0,
    (sum, doc) => sum + (doc.data()['quantity'] as int),
  );

  return kWeeklyLimit - weeklyTotal;
}
