import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_panel_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String name = "User";
  String surname = "";
  String email = "No email";
  String iban = "No IBAN";
  String balance = "0";
  String role = "User";
  String profilePictureUrl = "";
  bool _loading = false;
  bool _isAdmin = false; // ✅ Check if user is Admin

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  /// ✅ Fetch User Data from Firebase
  Future<void> _fetchUserData() async {
    setState(() => _loading = true);

    User? user = _auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (userDoc.exists && userDoc.data() != null) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      setState(() {
        name = userData['name'] ?? "User";
        surname = userData['surname'] ?? "";
        email = userData['email'] ?? "No email";
        iban = userData['iban'] ?? "No IBAN";
        balance = userData['funds']?.toString() ?? "0";
        profilePictureUrl = userData['profilePictureUrl'] ?? "";
        role = userData['role'] ?? "User";
        _isAdmin = role == "admin";
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
  Future<void> _uploadProfilePicture(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);
    User? user = _auth.currentUser;

    if (user != null) {
      String filePath = "profile_pictures/${user.uid}.jpg";
      TaskSnapshot uploadTask = await _storage.ref(filePath).putFile(imageFile);
      String newProfileUrl = await uploadTask.ref.getDownloadURL();

      await _firestore.collection('users').doc(user.uid).update({
        'profilePictureUrl': newProfileUrl,
      });

      setState(() {
        profilePictureUrl = newProfileUrl;
      });
    }
  }

  /// ✅ Show Image Upload Options (Camera/Gallery)
  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text("Take a Photo"),
                onTap: () {
                  Navigator.pop(context);
                  _uploadProfilePicture(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _uploadProfilePicture(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchUserData, // ✅ Refresh Profile Data
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ✅ Profile Picture & Upload
            Center(
              child: GestureDetector(
                onTap: _showImageSourceOptions,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: profilePictureUrl.isNotEmpty ? NetworkImage(profilePictureUrl) : null,
                  child: profilePictureUrl.isEmpty ? Icon(Icons.person, size: 60, color: Colors.white) : null,
                ),
              ),
            ),
            SizedBox(height: 20),

            // ✅ User Info
            Text("$name $surname", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text(email, style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 20),
            Divider(),

            // ✅ IBAN & Balance
            ListTile(
              leading: Icon(Icons.credit_card),
              title: Text("IBAN"),
              subtitle: Text(iban),
            ),
            ListTile(
              leading: Icon(Icons.account_balance_wallet),
              title: Text("Balance"),
              subtitle: Text("\$$balance"),
            ),
            ListTile(
              leading: Icon(Icons.verified_user),
              title: Text("Role"),
              subtitle: Text(role),
            ),

            // ✅ Admin Panel Button (Only for Admins)
            if (_isAdmin)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminPanelScreen())),
                  icon: Icon(Icons.admin_panel_settings),
                  label: Text("Admin Panel"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                ),
              ),

            // ✅ Logout Button
            SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _logout,
              icon: Icon(Icons.exit_to_app),
              label: Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
