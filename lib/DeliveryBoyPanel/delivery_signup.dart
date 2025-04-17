import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodapp/DeliveryBoyPanel/Dashboard.dart';
import 'package:foodapp/DeliveryBoyPanel/delivery_login.dart';
import 'package:foodapp/pages/login.dart'; // Import the relevant page to navigate back to login

class DeliveryBoySignUp extends StatefulWidget {
  const DeliveryBoySignUp({super.key});

  @override
  State<DeliveryBoySignUp> createState() => _DeliveryBoySignUpState();
}

class _DeliveryBoySignUpState extends State<DeliveryBoySignUp> {
  String name = "", aadhaarCardNumber = "", contactNumber = "", email = "", password = "", earnings ="";
  final _formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController aadhaarCardController = TextEditingController();
  TextEditingController contactNumberController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Future<void> userSignUp() async {
    try {
      // Sign up the user with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);

      // Save the delivery boy details to Firestore
      await FirebaseFirestore.instance.collection("delivery_boys").doc(userCredential.user!.uid).set({
        'name': name,
        'aadhaarCardNumber': aadhaarCardNumber,
        'contactNumber': contactNumber,
        'email': email,
        'earnings': ""
      });

      // Navigate to the login page after successful sign-up
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DeliveryHome()));
    } on FirebaseAuthException catch (e) {
      // Handle FirebaseAuth errors
      if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.orangeAccent,
          content: Text(
            "Email is already in use",
            style: TextStyle(fontSize: 20.0),
          ),
        ));
      } else if (e.code == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.orangeAccent,
          content: Text(
            "Password is too weak",
            style: TextStyle(fontSize: 20.0),
          ),
        ));
      }
    } catch (e) {
      // Catch any other errors
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.orangeAccent,
        content: Text(
          "An error occurred. Please try again.",
          style: TextStyle(fontSize: 20.0),
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Container(
          child: Stack(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 2.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFDAB9),
                      Color(0xFFe74b1a),
                    ],
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: MediaQuery.of(context).size.height / 3),
                height: MediaQuery.of(context).size.height / 1.5,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40))),
                child: Text(" "),
              ),
              Container(
                margin: EdgeInsets.only(top: 60.0, left: 20.0, right: 20.0),
                child: Column(
                  children: [
                    Center(
                        child: Image.asset(
                          "images/Logo.png",
                          width: MediaQuery.of(context).size.width / 1.5,
                          fit: BoxFit.cover,
                        )),
                    SizedBox(height: 50.0),
                    GestureDetector(
                      onTap: () {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            name = nameController.text;
                            aadhaarCardNumber = aadhaarCardController.text;
                            contactNumber = contactNumberController.text;
                            email = emailController.text;
                            password = passwordController.text;
                          });
                          userSignUp();
                        }
                      },
                      child: Material(
                        elevation: 5.0,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: EdgeInsets.only(left: 20.0, right: 20.0),
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height / 1.6,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                SizedBox(height: 30.0),
                                Text("Sign Up as Delivery Boy", style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold)),
                                SizedBox(height: 20.0),
                                TextFormField(
                                  controller: nameController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please Enter Name';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(hintText: "Name", prefixIcon: Icon(Icons.person)),
                                ),
                                SizedBox(height: 20.0),
                                TextFormField(
                                  controller: aadhaarCardController,
                                  keyboardType: TextInputType.number, // Ensures the numeric keyboard is shown
                                  validator: (value) {
                                    // Check if the field is empty or not 12 digits
                                    if (value == null || value.isEmpty) {
                                      return 'Please Enter Aadhaar Card Number';
                                    } else if (value.length != 12) {
                                      return 'Aadhaar Card Number must be exactly 12 digits';
                                    } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                      return 'Aadhaar Card Number should only contain digits';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    hintText: "Aadhaar Card Number",
                                    prefixIcon: Icon(Icons.credit_card),
                                  ),
                                ),
                                SizedBox(height: 20.0),
                                TextFormField(
                                  controller: contactNumberController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please Enter Contact Number';
                                    }else if (value.length != 10) {
                                      return 'Contact Number must be exactly 10 digits';
                                    } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                      return 'Contact should only contain digits';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(hintText: "Contact Number", prefixIcon: Icon(Icons.phone)),
                                ),
                                SizedBox(height: 20.0),
                                TextFormField(
                                  controller: emailController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please Enter Email';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(hintText: "Email", prefixIcon: Icon(Icons.email)),
                                ),
                                SizedBox(height: 30.0),
                                TextFormField(
                                  controller: passwordController,
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please Enter Password';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(hintText: "Password", prefixIcon: Icon(Icons.lock)),
                                ),
                                SizedBox(height: 20.0),
                                Material(
                                  elevation: 5.0,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 8.0),
                                    width: 200,
                                    decoration: BoxDecoration(color: Color(0Xffff5722), borderRadius: BorderRadius.circular(20)),
                                    child: Center(
                                        child: Text(
                                          "SIGN UP",
                                          style: TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
                                        )),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 40.0),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => DeliveryBoyLogin()));
                      },
                      child: Text("Already have an account? Log In", style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
