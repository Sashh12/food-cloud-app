import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodapp/Kitchen/k_modifyitems.dart';
import 'package:foodapp/Kitchen/k_subscribeOrders.dart';
import 'package:foodapp/service/auth.dart';
import 'package:foodapp/Kitchen/add_food.dart';
import 'package:foodapp/Kitchen/Kitchen_orders.dart';
import 'package:foodapp/Kitchen/Kitchen_register.dart';
import 'package:foodapp/widget/widget_support.dart';

class VendorHome extends StatefulWidget {
  const VendorHome({super.key});

  @override
  State<VendorHome> createState() => _VendorHomeState();
}

class _VendorHomeState extends State<VendorHome> {
  String? loggedInKitchenId; // Store kitchenId (same as uid)

  @override
  void initState() {
    super.initState();
    fetchKitchenId(); // Fetch kitchenId on init
  }

  // Fetch the kitchenId which is the same as the UID
  Future<void> fetchKitchenId() async {
    // Get the currently logged-in user
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      setState(() {
        loggedInKitchenId = currentUser.uid; // Set kitchenId as the UID
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: EdgeInsets.only(top: 50.0, left: 20.0, right: 20.0),
        child: Column(
          children: [
            Center(
              child: Text(
                "DashBoard",
                style: AppWidget.HeaderLineTextFieldStyle(),
              ),
            ),
            SizedBox(height: 20.0),
            Expanded( // Ensures the scrollable content fits within the screen
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddFood(kitchenId: loggedInKitchenId!),
                          ),
                        );
                      },
                      child: Material(
                        elevation: 10.0,
                        borderRadius: BorderRadius.circular(10),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFFAF0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(6.0),
                                  child: Image.asset(
                                    "images/dish.png",
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(width: 30.0),
                                Text(
                                  "Add Food Items",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.0),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => VendorsOrders()),
                        );
                      },
                      child: Material(
                        elevation: 10.0,
                        borderRadius: BorderRadius.circular(10),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFFAF0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(6.0),
                                  child: Image.asset(
                                    "images/order.png",
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(width: 30.0),
                                Text(
                                  "Orders",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.0),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                KModifyitems(kitchenId: loggedInKitchenId!),
                          ),
                        );
                      },
                      child: Material(
                        elevation: 10.0,
                        borderRadius: BorderRadius.circular(10),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFFAF0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(6.0),
                                  child: Image.asset(
                                    "images/menu.png",
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(width: 30.0),
                                Text(
                                  "Food Items",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.0),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VendorsSubscriptionOrders(),
                          ),
                        );
                      },
                      child: Material(
                        elevation: 10.0,
                        borderRadius: BorderRadius.circular(10),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFFAF0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(6.0),
                                  child: Image.asset(
                                    "images/membership.png",
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(width: 30.0),
                                Text(
                                  "Subscriptions Orders",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.0),
                  ],
                ),
              ),
            ),
            Divider(),
            GestureDetector(
              onTap: () {
                AuthMethods().SignOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => KitchenSignUp(),
                  ), // Replace 'SignUpPage' with your actual signup widget
                );
              },
              child: Container(
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: Colors.black,
                    ),
                    SizedBox(width: 20.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "LogOut",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20.0,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
            SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }
}

