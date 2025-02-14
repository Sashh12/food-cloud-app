import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodapp/DeliveryBoyPanel/Dashboard.dart';
import 'package:foodapp/DeliveryBoyPanel/delivery_signup.dart';
import 'package:foodapp/widget/widget_support.dart';

class DeliveryBoyLogin extends StatefulWidget {
  const DeliveryBoyLogin({super.key});

  @override
  State<DeliveryBoyLogin> createState() => _DeliveryBoyLoginState();
}

class _DeliveryBoyLoginState extends State<DeliveryBoyLogin> {
  String email = "", password = "";
  final _formKey = GlobalKey<FormState>();

  TextEditingController deliveryMailController = TextEditingController();
  TextEditingController deliveryPasswordController = TextEditingController();

  Future<void> userLogin() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Print email for debugging
      print("Checking Firestore for email: $email");

      QuerySnapshot<Map<String, dynamic>> deliverySnapshot = await FirebaseFirestore.instance
          .collection("delivery_boys")
          .where('email', isEqualTo: email) // Changed 'Email' to 'email'
          .limit(1)
          .get();

      if (deliverySnapshot.docs.isNotEmpty) {
        print("Delivery Boy found: ${deliverySnapshot.docs.first.data()}");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DeliveryHome()),
        );
      } else {
        print("No matching delivery boy found in Firestore.");
        _showSnackBar("No Delivery Boy found for this Email");
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showSnackBar("No User Found for that Email");
      } else if (e.code == 'wrong-password') {
        _showSnackBar("Wrong Password Provided by User");
      }
    } catch (e) {
      _showSnackBar("An error occurred. Please try again.");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.orangeAccent,
      content: Text(
        message,
        style: TextStyle(fontSize: 20.0),
      ),
    ));
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
                height: MediaQuery.of(context).size.height / 3,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40))),
              ),
              Container(
                margin: EdgeInsets.only(
                  top: 60.0,
                  left: 20.0,
                  right: 20.0,
                ),
                child: Column(
                  children: [
                    Center(
                      child: Image.asset(
                        "images/Logo.png",
                        width: MediaQuery.of(context).size.width / 1.5,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 50.0),
                    GestureDetector(
                      onTap: () {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            email = deliveryMailController.text.trim();
                            password = deliveryPasswordController.text.trim();
                          });
                          userLogin();
                        }
                      },
                      child: Material(
                        elevation: 5.0,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: EdgeInsets.only(left: 20.0, right: 20.0),
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height / 2.6,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10)),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                SizedBox(height: 30.0),
                                Text("Login as Delivery Boy", style: AppWidget.SemiBoldFieldStyle()),
                                SizedBox(height: 30.0),
                                TextFormField(
                                  controller: deliveryMailController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please Enter Email';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                      hintText: "Email",
                                      prefixIcon: Icon(Icons.email_outlined)),
                                ),
                                SizedBox(height: 30.0),
                                TextFormField(
                                  controller: deliveryPasswordController,
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please Enter Password';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                      hintText: "Password",
                                      prefixIcon: Icon(Icons.password_outlined)),
                                ),
                                SizedBox(height: 40.0),
                                Material(
                                  elevation: 5.0,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 8.0),
                                    width: 200,
                                    decoration: BoxDecoration(
                                        color: Color(0Xffff5722),
                                        borderRadius: BorderRadius.circular(20)),
                                    child: Center(
                                      child: Text(
                                        "LOGIN",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18.0,
                                            fontFamily: 'Poppins1',
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.0),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => DeliveryBoySignUp()));
                      },
                      child: Text(
                        "Don't have an account? Sign up",
                        style: AppWidget.SemiBoldFieldStyle2(),
                      ),
                    ),
                    SizedBox(height: 20.0),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
