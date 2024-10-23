import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodapp/pages/address.dart';
import 'package:foodapp/pages/bottomnav.dart';
import 'package:foodapp/service/database.dart';
import 'package:foodapp/widget/widget_support.dart';

class Order extends StatefulWidget {
  const Order({super.key});

  @override
  State<Order> createState() => _OrderState();
}

class _OrderState extends State<Order> {
  String? id, wallet;
  int total = 0, amount2 = 0;
  Stream? foodStream;

  @override
  void initState() {
    super.initState();
    ontheload();
    startTimer();
  }

  void startTimer() {
    Timer(Duration(seconds: 2), () {
      amount2 = total;
      setState(() {});
    });
  }

  Future<void> getUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    id = user?.uid;

    if (id != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .get();
      wallet = userDoc["Wallet"];
    }

    setState(() {});
  }

  ontheload() async {
    await getUserData();
    if (id != null) {
      foodStream = await DatabaseMethods().getFoodCart(id!);
      setState(() {});
    }
  }

  Widget foodCart() {
    return StreamBuilder(
      stream: foodStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: snapshot.data.docs.length,
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              itemBuilder: (context, index) {
                DocumentSnapshot ds = snapshot.data.docs[index];
                total += int.parse(ds["Total"]);
                return Container(
                  margin: EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
                  child: Material(
                    elevation: 5.0,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
                      padding: EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Container(
                            height: 50.0,
                            width: 40.0,
                            decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(child: Text(ds["Quantity"])),
                          ),
                          SizedBox(width: 10.0),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Image.network(ds["Image"], height: 90, width: 90, fit: BoxFit.cover),
                          ),
                          SizedBox(width: 10.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ds["Name"],
                                  style: AppWidget.NormalText(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text("₹ " + ds["Total"], style: AppWidget.NormalText()),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              });
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Future<void> placeOrder(String selectedAddress) async {
    if (id != null) {
      if (wallet != null) {
        int amount = int.parse(wallet!) - amount2;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(id)
            .update({"Wallet": amount.toString()});

        var cartItems = await FirebaseFirestore.instance
            .collection("users")
            .doc(id)
            .collection("Cart")
            .get();

        String orderId = FirebaseFirestore.instance.collection("orders").doc().id;
        await FirebaseFirestore.instance.collection("orders").doc(orderId).set({
          "userId": id,
          "totalAmount": total,
          "orderDate": Timestamp.now(),
          "items": cartItems.docs.map((doc) => doc.data()).toList(),
          "address": selectedAddress, // Use the selected address for the order
        });

        for (var doc in cartItems.docs) {
          await FirebaseFirestore.instance
              .collection("users")
              .doc(id)
              .collection("Cart")
              .doc(doc.id)
              .delete();
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Order placed successfully!"),
          duration: Duration(seconds: 2),
        ));

        await Future.delayed(Duration(seconds: 2));

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNav()));
      }
    }
  }

  Future<void> selectAddress() async {
    User? user = FirebaseAuth.instance.currentUser;
    String? userId = user?.uid;

    if (userId != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      List<dynamic> addresses = userDoc.get('addresses') ?? [];

      // Show address selection dialog
      String? selectedAddress = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select an Address'),
            content: Container(
              width: double.minPositive,
              height: 200,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: addresses.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(addresses[index]),
                          onTap: () {
                            Navigator.of(context).pop(addresses[index]); // Return the selected address
                          },
                        );
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddAddressScreen()), // Navigate to Add Address screen
                      );
                    },
                    child: Text('Add New Address'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('Cancel'),
              ),
            ],
          );
        },
      );

      if (selectedAddress != null) {
        // Proceed to place the order with the selected address
        await placeOrder(selectedAddress);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.only(top: 60.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              elevation: 2.0,
              child: Container(
                padding: EdgeInsets.only(bottom: 10.0),
                child: Center(child: Text("Food Cart")),
              ),
            ),
            SizedBox(height: 20.0),
            Container(
              height: MediaQuery.of(context).size.height / 2,
              child: foodCart(),
            ),
            Spacer(),
            Divider(),
            Padding(
              padding: EdgeInsets.only(left: 10.0, right: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Price", style: AppWidget.BoldTextFieldStyle()),
                  Text("\₹ " + total.toString(), style: AppWidget.SemiBoldFieldStyle()),
                ],
              ),
            ),
            SizedBox(height: 20.0),
            GestureDetector(
              onTap: () async {
                await selectAddress(); // Select an address before placing the order
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10)),
                margin: EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
                child: Center(
                    child: Text("Checkout", style: TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
