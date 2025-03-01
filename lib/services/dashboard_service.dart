import 'firestore_service.dart';

class DashboardService {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> loadUserDashboard(String uid) async {
    var userData = await _firestoreService.getUserData(uid);
    if (userData != null) {
      print("User Name: ${userData['name']}");
      print("Balance: \$${userData['funds']}");
      print("IBAN: ${userData['iban']}");
      print("Transactions: ${userData['transactions']}");
    } else {
      print("User data not found");
    }
  }
}
