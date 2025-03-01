import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> requestMoney(String receiverIban, double amount) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return "User not logged in.";

      DocumentSnapshot senderDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!senderDoc.exists) return "Requester account not found.";

      String senderIban = senderDoc['iban'];

      QuerySnapshot receiverQuery = await _firestore
          .collection('users')
          .where('iban', isEqualTo: receiverIban)
          .limit(1)
          .get();

      if (receiverQuery.docs.isEmpty) return "Receiver IBAN not found.";
      DocumentSnapshot receiverDoc = receiverQuery.docs.first;
      String receiverUid = receiverDoc.id;

      String requestId = _firestore.collection('money_requests').doc().id;

      await _firestore.collection('money_requests').doc(requestId).set({
        'requestId': requestId,
        'amount': amount,
        'date': FieldValue.serverTimestamp(),
        'requesterId': user.uid,
        'requesterIban': senderIban,
        'receiverId': receiverUid,
        'receiverIban': receiverIban,
        'status': 'pending',
      });

      return "Money request sent successfully!";
    } catch (e) {
      return "Request failed: $e";
    }
  }
}
