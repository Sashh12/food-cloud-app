import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:foodapp/pages/P_orderhistory.dart';
import 'package:foodapp/pages/signup.dart';
import 'package:foodapp/pages/subscribe.dart';
import 'package:foodapp/service/auth.dart';
import 'package:image_picker/image_picker.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? profile, name, email;
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> getImage() async {
    var image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
      await uploadItem();
    }
  }

  Future<void> uploadItem() async {
    if (selectedImage != null) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference firebaseStorageRef =
      FirebaseStorage.instance.ref().child("profileImages").child(fileName);
      final UploadTask task = firebaseStorageRef.putFile(selectedImage!);
      var downloadUrl = await (await task).ref.getDownloadURL();

      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Save the image URL directly to the user's document in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'profileImage': downloadUrl, // Use the correct field name in your Firestore
        });
      }
      setState(() {
        profile = downloadUrl; // Update local state if needed
      });
    }
  }

  Future<void> fetchUserData() async {
    try {
      User? user = auth.currentUser;
      if (user != null) {
        print('Fetching data for user ID: ${user.uid}');
        DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (snapshot.exists) {
          Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

          print('Fetched data: $data');

          if (data != null) {
            setState(() {
              name = data['Name'];
              email = data['Email'];
              profile = data['profileImage']; // Ensure this matches your Firestore structure
            });
          }
        } else {
          print('No document exists for user ID: ${user.uid}');
        }
      } else {
        print('No user is currently logged in.');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: name == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView( // Added SingleChildScrollView
        child: Container(
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    padding: EdgeInsets.only(top: 45.0, left: 20.0, right: 20.0),
                    height: MediaQuery.of(context).size.height / 4.3,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.elliptical(MediaQuery.of(context).size.width, 105.0),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height / 6.5),
                      child: Material(
                        elevation: 10.0,
                        borderRadius: BorderRadius.circular(60),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: GestureDetector(
                            onTap: getImage,
                            child: profile == null
                                ? Image.asset("images/boy.jpg", height: 120, width: 120, fit: BoxFit.cover)
                                : Image.network(profile!, height: 120, width: 120, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 70.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          name ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Merriweather',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.0),
              _buildInfoCard(Icons.person, "Name", name),
              SizedBox(height: 10.0),
              _buildInfoCard(Icons.email, "Email", email),
              SizedBox(height: 10.0),
              _buildOrderHistory(),
              SizedBox(height: 10.0),
              _buildSubscribeButton(),
              SizedBox(height: 10.0),
              _buildDeleteAccountButton(),
              SizedBox(height: 10.0),
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildInfoCard(IconData icon, String title, String? value) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.0),
      child: Material(
        borderRadius: BorderRadius.circular(10),
        elevation: 2.0,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.black),
              SizedBox(width: 20.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    value ?? '',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHistory() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => OrderHistoryPage()));
      },
      child: _buildActionButton(Icons.history_outlined, "Order History"),
    );
  }

  Widget _buildDeleteAccountButton() {
    return GestureDetector(
      onTap: () {
        AuthMethods().deleteUser();
      },
      child: _buildActionButton(Icons.delete, "Delete Account"),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () {
        AuthMethods().SignOut();
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => SignUp()));
      },
      child: _buildActionButton(Icons.logout, "LogOut"),
    );
  }

  Widget _buildSubscribeButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => SubscribePage()));
      },
      child: _buildActionButton(Icons.shopping_basket_outlined, "Subscribe & Save"),
    );
  }


  Widget _buildActionButton(IconData icon, String title) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.0),
      child: Material(
        borderRadius: BorderRadius.circular(10),
        elevation: 2.0,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.black),
              SizedBox(width: 20.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
