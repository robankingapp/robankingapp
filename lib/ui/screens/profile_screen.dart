import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'admin_panel_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String name = "User";
  String surname = "";
  String email = "No email";
  String iban = "No IBAN";
  String balance = "0";
  String role = "User";
  File? _localProfileImage;
  bool _loading = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadLocalImage();
  }

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
        role = userData['role'] ?? "User";
        _isAdmin = role == "admin";
      });
    }

    setState(() => _loading = false);
  }

  Future<bool> _requestPermissions() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 33) {
      final photosStatus = await Permission.photos.request();
      final cameraStatus = await Permission.camera.request();
      return photosStatus.isGranted && cameraStatus.isGranted;
    } else {
      final storageStatus = await Permission.storage.request();
      final cameraStatus = await Permission.camera.request();
      return storageStatus.isGranted && cameraStatus.isGranted;
    }
  }

  Future<File> _getLocalProfileImageFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/profile_picture.png');
  }

  Future<void> _loadLocalImage() async {
    final file = await _getLocalProfileImageFile();
    if (await file.exists()) {
      setState(() {
        _localProfileImage = file;
      });
    }
  }

  Future<void> _uploadProfilePicture(ImageSource source) async {
    try {
      if (!await _requestPermissions()) return;

      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(toolbarTitle: 'Crop Image', lockAspectRatio: true),
          IOSUiSettings(title: 'Crop Image', aspectRatioLockEnabled: true),
        ],
      );

      if (!mounted || cropped == null) return;

      final croppedFile = File(cropped.path);
      if (!await croppedFile.exists()) return;

      final savePath = (await _getLocalProfileImageFile()).path;
      File savedImage;

      try {
        savedImage = await croppedFile.copy(savePath);
      } catch (_) {
        final bytes = await croppedFile.readAsBytes();
        savedImage = await File(savePath).writeAsBytes(bytes);
      }

      setState(() {
        _localProfileImage = savedImage;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profile picture saved locally!")),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save profile picture.")),
      );
    }
  }

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

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _fetchUserData();
              _loadLocalImage();
            },
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: _showImageSourceOptions,
                child: FutureBuilder<File>(
                  future: _getLocalProfileImageFile().timeout(Duration(seconds: 3)),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                      final file = snapshot.data!;
                      return file.existsSync()
                          ? CircleAvatar(
                        radius: 60,
                        backgroundImage: FileImage(file),
                      )
                          : CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        child: Icon(Icons.person, size: 60, color: Colors.white),
                      );
                    } else if (snapshot.hasError) {
                      return CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.red[100],
                        child: Icon(Icons.error, size: 60, color: Colors.red),
                      );
                    } else {
                      return CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        child: CircularProgressIndicator(),
                      );
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "$name $surname",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(email, style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 20),
            Divider(),
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
            if (_isAdmin)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdminPanelScreen()),
                  ),
                  icon: Icon(Icons.admin_panel_settings),
                  label: Text("Admin Panel"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                ),
              ),
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
