import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodapp/pages/bottomnav.dart';
import 'package:foodapp/pages/login.dart';
// import 'package:foodapp/service/database.dart';
import 'package:foodapp/Kitchen/Kitchen_login.dart';
import 'package:foodapp/widget/widget_support.dart';
// import 'package:random_string/random_string.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pinput/pinput.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final FirebaseAuth auth = FirebaseAuth.instance;

  static String verify = "";

  String email = "", password = "", name = "", phone= "",code = "";

  TextEditingController namecontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController mailcontroller = TextEditingController();
  TextEditingController phonecontroller = TextEditingController();
  TextEditingController countrycodecontroller = TextEditingController();

  final _formkey = GlobalKey<FormState>();

  @override
  void initState() {
    countrycodecontroller.text= "+91";
    super.initState();
  }

  // registration() async {
  //   if (password.isNotEmpty && namecontroller.text.isNotEmpty && mailcontroller.text.isNotEmpty && phonecontroller.text.isNotEmpty && countrycodecontroller.text.isNotEmpty) {
  //     try {
  //       UserCredential userCredential = await FirebaseAuth.instance
  //           .createUserWithEmailAndPassword(email: email, password: password);
  //
  //       User? user = userCredential.user;
  //
  //       if (user != null) {
  //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //             content: Text("Registered Successfully", style: TextStyle(fontSize: 20.0),)));
  //
  //         // Use the UID from Firebase Auth
  //         String uid = user.uid;
  //
  //         // Create the user document with UID as document ID
  //         Map<String, dynamic> addUserInfo = {
  //           "Name": namecontroller.text,
  //           "Email": mailcontroller.text,
  //           "Phone": countrycodecontroller.text + phonecontroller.text,
  //           "Wallet": "0",
  //           "Loyalty": 0,
  //           "Id": uid, // Store UID instead of random ID
  //         };
  //
  //         // Store user details in Firestore
  //         await FirebaseFirestore.instance.collection('users').doc(uid).set(addUserInfo);
  //
  //         // Navigate to BottomNav after successful registration
  //         Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNav()));
  //       }
  //     } on FirebaseAuthException catch (e) {
  //       if (e.code == 'weak-password') {
  //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //             backgroundColor: Colors.orangeAccent,
  //             content: Text("Password provided is too weak", style: TextStyle(fontSize: 18.0),)));
  //       } else if (e.code == "email-already-in-use") {
  //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //             backgroundColor: Colors.orangeAccent,
  //             content: Text("Account already exists", style: TextStyle(fontSize: 18.0),)));
  //       }
  //     }
  //   }
  // }
  registration() async {
    String code = this.code;
    if (password.isNotEmpty && namecontroller.text.isNotEmpty && mailcontroller.text.isNotEmpty && phonecontroller.text.isNotEmpty && countrycodecontroller.text.isNotEmpty) {
      try {
        // Register with email/password
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        User? user = userCredential.user;

        if (user != null) {
          // After email/password registration, link phone number
          // await user.updatePhoneNumber(PhoneAuthProvider.credential(verificationId: verify, smsCode: code));

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Registered Successfully", style: TextStyle(fontSize: 20.0))));

          String uid = user.uid;

          // Store user info in Firestore
          Map<String, dynamic> addUserInfo = {
            "Name": namecontroller.text,
            "Email": mailcontroller.text,
            "Phone": countrycodecontroller.text + phonecontroller.text,
            "Wallet": "0",
            "Loyalty": 0,
            "Id": uid,
          };

          await FirebaseFirestore.instance.collection('users').doc(uid).set(addUserInfo);

          // Navigate to BottomNav after successful registration
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNav()));
        }
      } on FirebaseAuthException catch (e) {
        // Handle registration errors (weak password, email already in use)
        if (e.code == 'weak-password') {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.orangeAccent,
              content: Text("Password provided is too weak", style: TextStyle(fontSize: 18.0))));
        } else if (e.code == "email-already-in-use") {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.orangeAccent,
              content: Text("Account already exists", style: TextStyle(fontSize: 18.0))));
        }
      }
    }
  }

  Widget buildPhoneVerificationDialog(BuildContext context) {
    // String code="";
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: TextStyle(
        fontSize: 20,
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
      ),
    );

    return AlertDialog(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Phone Verification",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            SizedBox(height: 30),
            Pinput(
              length: 6,
              // Uncomment if needed:
              defaultPinTheme: defaultPinTheme,
              showCursor: true,
              // onCompleted: (pin) => print(pin),
              onChanged: (value) {
                setState(() {
                  code = value;
                });
              },
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF4444),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  // Ensure phone verification first, then proceed with registration
                  PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: verify, smsCode: code);

                  await auth.signInWithCredential(credential);  // Sign-in or link with phone number
                  Navigator.pop(context); // close the dialog
                  registration();  // Proceed to email/password registration
                },

                child: Text("Verify Phone Number", style: TextStyle(color: Colors.white, fontSize: 18.0, fontFamily: 'Poppins1', fontWeight: FontWeight.bold)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close the dialog
                // Navigator.pushNamed(context, "/edit-number"); // optional navigation
              },
              child: Text(
                "Edit Phone Number?",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
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
                      Color(0xFFFFD5C5),
                      Color(0xFFFA7474),
                    ],
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: MediaQuery.of(context).size.height / 3),
                height: MediaQuery.of(context).size.height / 2.5,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40))),
              ),
              Container(
                margin: EdgeInsets.only(top: 60.0, left: 20.0, right: 20.0),
                child: Column(children: [
                  Center(child: Image.asset("images/Logo.png", width: MediaQuery.of(context).size.width / 1.5, fit: BoxFit.cover)),
                  SizedBox(height: 50.0),
                  Material(
                    elevation: 5.0,
                    borderRadius: BorderRadius.circular(10),
                    child: SingleChildScrollView(
                      child: Container(
                        padding: EdgeInsets.only(left: 20.0, right: 20.0),
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height / 1.6,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                        child: Form(
                          key: _formkey,
                          child: Column(children: [
                            SizedBox(height: 30.0),
                            Text("Sign Up", style: AppWidget.HeaderLineTextFieldStyle()),
                            SizedBox(height: 10.0),
                            TextFormField(
                              controller: namecontroller,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter name';
                                }
                                return null;
                              },
                              decoration: InputDecoration(hintText: "Name",  prefixIcon: Icon(Icons.person_outline)),
                            ),
                            SizedBox(height: 30.0),

                            // TextFormField(
                            //   controller: mailcontroller,
                            //   validator: (value) {
                            //     if (value == null || value.isEmpty) {
                            //       return 'Please enter email';
                            //     }
                            //     return null;
                            //   },
                            //   decoration: InputDecoration(hintText: "Email", prefixIcon: Icon(Icons.email_outlined)),
                            // ),
                            TextFormField(
                              controller: mailcontroller,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter email';
                                }
                                // Email regex pattern for validation
                                String pattern =
                                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
                                RegExp regExp = RegExp(pattern);

                                if (!regExp.hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null; // Valid email
                              },
                              decoration: InputDecoration(
                                hintText: "Email",
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                            SizedBox(height: 30.0),
                            // Row(
                            //   children: [
                            //     SizedBox(width: 10,),
                            //     SizedBox(width: 40,
                            //       child: TextFormField(
                            //         controller: countrycodecontroller,
                            //         decoration: InputDecoration(
                            //             border: InputBorder.none),
                            //       ),
                            //     ),
                            //
                            //     Text("|",style: TextStyle(fontSize: 33,color: Colors.grey),),
                            //     SizedBox(width: 10,),
                            //     Expanded(child: TextFormField(decoration: InputDecoration(
                            //         border: InputBorder.none,hintText: "Phone Number"),),)
                            //   ],
                            // ),
                            TextFormField(
                              keyboardType: TextInputType.phone,
                              controller: phonecontroller,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter phone number';
                                  }
                                  if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                                    return 'Phone number must be exactly 10 digits';
                                  }
                                  return null;
                                },
                              decoration: InputDecoration(
                                hintText: "Phone Number",
                                prefixIcon: Container(
                                  width: 60,
                                  padding: EdgeInsets.only(left: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 35,
                                        child: TextFormField(
                                          controller: countrycodecontroller,
                                          decoration: InputDecoration(
                                            hintText: "+91",
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          style: TextStyle(fontSize: 14),
                                          keyboardType: TextInputType.phone,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Text("|", style: TextStyle(fontSize: 20, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 30.0),
                            TextFormField(
                              controller: passwordcontroller,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter password';
                                }

                                // Check if the password is at least 6 characters long and contains at least one numeric digit
                                if (value.length < 6) {
                                  return 'Password should be at least 6 characters';
                                }

                                // Check if the password contains at least one numeric digit
                                if (!RegExp(r'[0-9]').hasMatch(value)) {
                                  return 'Password should contain at least one number';
                                }

                                return null;
                              },
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: "Password",
                                prefixIcon: Icon(Icons.password_outlined),
                              ),
                            ),
                            SizedBox(height: 20.0),
                            GestureDetector(

                              // onTap: () async {
                              //   if (_formkey.currentState!.validate()) {
                              //     setState(() {
                              //       email = mailcontroller.text;
                              //       name = namecontroller.text;
                              //       password = passwordcontroller.text;
                              //       phone = countrycodecontroller.text + phonecontroller.text;
                              //     });
                              //
                              //     String phoneNumberFull = countrycodecontroller.text + phonecontroller.text;
                              //
                              //     await FirebaseAuth.instance.verifyPhoneNumber(
                              //       phoneNumber: phoneNumberFull,
                              //       verificationCompleted: (PhoneAuthCredential credential) {
                              //         // Optional: auto-sign-in if verification is instant
                              //       },
                              //       verificationFailed: (FirebaseAuthException e) {
                              //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Phone verification failed: ${e.message}")));
                              //       },
                              //       codeSent: (String verificationId, int? resendToken) {
                              //         verify = verificationId;
                              //
                              //         showDialog(
                              //           context: context,
                              //           barrierDismissible: false,
                              //           builder: (BuildContext context) => buildPhoneVerificationDialog(context),
                              //         );
                              //       },
                              //       codeAutoRetrievalTimeout: (String verificationId) {},
                              //     );
                              //   }
                              // },
                              onTap: () async {
                                if (_formkey.currentState!.validate()) {
                                  setState(() {
                                    email = mailcontroller.text.trim();
                                    name = namecontroller.text.trim();
                                    password = passwordcontroller.text;
                                    phone = phonecontroller.text.trim();
                                  });
                                  registration();

                                  // Trigger phone number verification
                                  // await FirebaseAuth.instance.verifyPhoneNumber(
                                  //   phoneNumber: countrycodecontroller.text + phone,
                                  //   verificationCompleted: (PhoneAuthCredential credential) async {
                                  //     // Auto-retrieval or instant verification (optional)
                                  //     await auth.signInWithCredential(credential);
                                  //   },
                                  //   verificationFailed: (FirebaseAuthException e) {
                                  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  //       backgroundColor: Colors.red,
                                  //       content: Text("Phone verification failed: ${e.message}", style: TextStyle(fontSize: 16)),
                                  //     ));
                                  //   },
                                  //   codeSent: (String verificationId, int? resendToken) {
                                  //     setState(() {
                                  //       verify = verificationId;
                                  //     });
                                  //
                                  //     // Show the OTP dialog
                                  //     showDialog(
                                  //       context: context,
                                  //       barrierDismissible: false,
                                  //       builder: (context) => buildPhoneVerificationDialog(context),
                                  //     );
                                  //   },
                                  //   codeAutoRetrievalTimeout: (String verificationId) {
                                  //     setState(() {
                                  //       verify = verificationId;
                                  //     });
                                  //   },
                                  //   timeout: Duration(seconds: 60),
                                  // );
                                }
                              },
                              child: Material(
                                elevation: 5.0,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  width: 200,
                                  decoration: BoxDecoration(color: Color(0xFFFF4444), borderRadius: BorderRadius.circular(20)),
                                  child: Center(child: Text("SIGNUP", style: TextStyle(color: Colors.white, fontSize: 18.0, fontFamily: 'Poppins1', fontWeight: FontWeight.bold))),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30.0),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => LogIn()));
                    },
                    child: Text("Already have an account? Login", style: AppWidget.SemiBoldFieldStyle2()),
                  ),
                  SizedBox(height: 15.0),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => VendorLogin()));
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Login as Cloud Kitchen", style: TextStyle(color: Color(0xFF2E2D2E), fontSize: 20.0, fontWeight: FontWeight.w200, fontFamily: 'Poppins')),
                        SizedBox(width: 8.0),
                        Icon(Icons.arrow_forward, color: Colors.black54),
                      ],
                    ),
                  ),
                ]),
              )
            ],
          ),
        ),
      ),
    );
  }
}
