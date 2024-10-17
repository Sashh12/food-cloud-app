import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
// import 'package:foodapp/pages/bottomnav.dart';
import 'package:foodapp/service/database.dart';
import 'package:foodapp/Kitchen/Kitchen_home.dart';
import 'package:foodapp/Kitchen/Kitchen_login.dart';
import 'package:foodapp/widget/widget_support.dart';
import 'package:random_string/random_string.dart';
import 'package:image_picker/image_picker.dart';


class KitchenSignUp extends StatefulWidget {
  const KitchenSignUp({super.key});

  @override
  State<KitchenSignUp> createState() => _KitchenSignUpState();
}

class _KitchenSignUpState extends State<KitchenSignUp> {
  String email = "", password = "", name = "", kitchenname = "";

  File? _image; // Variable to hold the selected image
  final picker = ImagePicker();

  TextEditingController businessnameController = TextEditingController();
  TextEditingController ownernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController hoursController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  Future<String?> uploadImage() async {
    if (_image == null) return null;
    try {
      // Create a unique file name
      String fileName = 'kitchen_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      // Upload the file to Firebase Storage
      TaskSnapshot snapshot = await FirebaseStorage.instance.ref(fileName).putFile(_image!);
      // Get the download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _selectImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> registration() async {
    if (password.isNotEmpty && ownernameController.text.isNotEmpty && emailController.text.isNotEmpty) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Registered Successfully", style: TextStyle(fontSize: 20.0),)));

        String userId = userCredential.user!.uid; // Fetching dynamically generated user ID
        String kitchenId = randomAlphaNumeric(10);
        String? imageUrl = _image != null ? await uploadImage() : null; // Upload image if selected

        Map<String, dynamic> addUserInfo = {
          "Name": ownernameController.text,
          "kitchenname": businessnameController.text,
          "Email": emailController.text,
          "KitchenId": kitchenId,
          "Address": addressController.text,
          "Contact": contactController.text,
          "Hours": hoursController.text,
          "ImageUrl": imageUrl, // Save the image URL
        };

        await DatabaseMethods().addCloudKitchenDetail(userId, addUserInfo);

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => VendorHome()));
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.orangeAccent,
              content: Text("Password Provided is too Weak", style: TextStyle(fontSize: 18.0),)));
        } else if (e.code == "email-already-in-use") {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.orangeAccent,
              content: Text("Account Already exists", style: TextStyle(fontSize: 18.0),)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height / 2.5,
              decoration: BoxDecoration( gradient: LinearGradient( begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFFFFD5C5), Color(0xFFFA7474),],),),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height / 10,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                "images/Logo.png",
                width: MediaQuery.of(context).size.width / 1.5,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height / 5,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                padding: EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 70.0),
                    // Image upload field
                    Center(
                      child: GestureDetector(
                        onTap: _selectImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _image != null ? FileImage(_image!) : null,
                          child: _image == null
                              ? Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.0),
                    Material(
                      elevation: 5.0,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: EdgeInsets.only(left: 20.0, right: 20.0),
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Sign Up",
                                style: AppWidget.HeaderLineTextFieldStyle(),
                              ),
                              SizedBox(height: 30.0),
                              TextFormField(
                                controller: ownernameController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Enter Name';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: "Name",

                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                              SizedBox(height: 30.0),
                              TextFormField(
                                controller: businessnameController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Enter Cloud Kitchen Name';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: "Cloud Kitchen Name",

                                  prefixIcon: Icon(Icons.restaurant),
                                ),
                              ),
                              SizedBox(height: 30.0),
                              TextFormField(
                                controller: emailController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Enter Email';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: "Email",

                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                              ),
                              SizedBox(height: 30.0),
                              TextFormField(
                                controller: passwordController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Enter Password';
                                  }
                                  return null;
                                },
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: "Password",

                                  prefixIcon: Icon(Icons.password_outlined),
                                ),
                              ),
                              SizedBox(height: 30.0),
                              TextFormField(
                                controller: addressController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Enter Address';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: "Address",

                                  prefixIcon: Icon(Icons.location_on_outlined),
                                ),
                              ),
                              SizedBox(height: 30.0),
                              TextFormField(
                                controller: contactController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Enter Contact Number';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: "Contact Number",

                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                              ),
                              SizedBox(height: 30.0),
                              TextFormField(
                                controller: hoursController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Enter Operating Hours';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: "Operating Hours",

                                  prefixIcon: Icon(Icons.access_time_outlined),
                                ),
                              ),
                              SizedBox(height: 30.0),
                              Center(
                                child: GestureDetector(
                                  onTap: () async {
                                    if (_formKey.currentState!.validate()) {
                                      setState(() {
                                        email = emailController.text;
                                        name = ownernameController.text;
                                        kitchenname = businessnameController.text;
                                        password = passwordController.text;
                                      });
                                      await registration(); // Ensure async call
                                    }
                                  },
                                  child: Material(
                                    elevation: 5.0,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 8.0),
                                      width: 200,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFFF4444),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "SIGNUP",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18.0,
                                            fontFamily: 'Poppins1',
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 50.0),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => VendorLogin()));
                      },
                      child: Text(
                        "Already have an account? Login",
                        style: AppWidget.SemiBoldFieldStyle2(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
