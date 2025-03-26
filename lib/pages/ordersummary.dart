import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodapp/pages/bottomnav.dart';

class OrderSummaryPage extends StatefulWidget {
  final String selectedAddress, selectedDeliveryTime;

  OrderSummaryPage({required this.selectedAddress, required this.selectedDeliveryTime});

  @override
  _OrderSummaryPageState createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  List<Map<String, dynamic>> cartItems = [];
  String? userId, wallet;
  int total = 0, loyalty= 0, appliedLoyalty = 0;
  int deliveryCharge = 40; // Example delivery charge
  bool useLoyaltyPoints = false;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
    getUserData();
  }

  Future<void> getUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    userId = user?.uid;

    if (userId != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      wallet = userDoc["Wallet"];
      loyalty = (userDoc["Loyalty"] ?? 0);// Fetch Loyalty field, default to 0 if not present
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> fetchCartItems() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ User not logged in");
      return;
    }

    String userId = user.uid;

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('Cart')
          .get();

      if (snapshot.docs.isEmpty) {
        print("❌ No items found in cart");
      }

      List<Map<String, dynamic>> fetchedItems = snapshot.docs
          .map((doc) => {
        ...doc.data() as Map<String, dynamic>,
        'id': doc.id, // Store document ID for debugging
      })
          .toList();

      print("📦 Cart Items Fetched: ${fetchedItems.length}");
      for (var item in fetchedItems) {
        print("🔹 Item: ${item['Name']}, Quantity: ${item['Quantity']}, Price: ${item['Total']}");
      }

      setState(() {
        cartItems = fetchedItems;
        total = cartItems.fold(0, (sum, item) => sum + (int.tryParse(item['Total'].toString()) ?? 0));
      });

      print("💰 Total Cart Value: $total");
    } catch (e) {
      print("❌ Error fetching cart items: $e");
    }
  }

  // Future<void> placeOrder() async {
  //   print("🔍 placeOrder() Function Called");
  //
  //   await getUserData();
  //
  //   if (!mounted) return; // Ensure widget is still mounted
  //   if (userId == null || wallet == null) {
  //     print("❌ User ID or Wallet is null");
  //     return;
  //   }
  //
  //   print("✅ User ID Found: $userId");
  //   print("💰 Wallet Amount: $wallet");
  //
  //   int walletAmount = int.tryParse(wallet!) ?? 0;
  //   int totalAmount = total + deliveryCharge; // Include delivery charge
  //   print("💵 Total Amount with Delivery: $totalAmount");
  //
  //   if (walletAmount < totalAmount) {
  //     print("❌ Insufficient Balance");
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //       content: Text("Insufficient balance! Please top up your wallet."),
  //       duration: Duration(seconds: 2),
  //     ));
  //     return;
  //   }
  //
  //   // Fetch Cart Items from Firestore
  //   QuerySnapshot cartSnapshot = await FirebaseFirestore.instance
  //       .collection("users")
  //       .doc(userId)
  //       .collection("Cart")
  //       .get();
  //
  //   if (cartSnapshot.docs.isEmpty) {
  //     print("❌ Cart is Empty");
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //         content: Text("Your cart is empty!"),
  //       ));
  //     }
  //     return;
  //   }
  //
  //   // Convert Firestore docs to a list of items
  //   List<Map<String, dynamic>> cartItems = cartSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  //
  //   print("🛒 Cart Items Found: ${cartItems.length}");
  //
  //   // Generate Order ID
  //   String orderId = FirebaseFirestore.instance.collection("Orders").doc().id;
  //   print("📌 Generated Order ID: $orderId");
  //
  //   // Deduct Wallet Amount
  //   int remainingAmount = max(0, walletAmount - totalAmount);
  //   print("💳 Deducting Wallet... Remaining Balance: $remainingAmount");
  //
  //   await FirebaseFirestore.instance
  //       .collection("users")
  //       .doc(userId)
  //       .update({"Wallet": remainingAmount.toString()});
  //   print("✅ Wallet Deducted Successfully");
  //
  //   // Save Order to Firestore
  //   await FirebaseFirestore.instance.collection("Orders").doc(orderId).set({
  //     "userId": userId,
  //     "totalAmount": totalAmount,
  //     "orderDate": Timestamp.now(),
  //     "items": cartItems,
  //     "address": widget.selectedAddress,
  //     "deliveryTime": widget.selectedDeliveryTime,
  //     "KitchenorderStatus": "Pending",
  //   });
  //
  //   print("✅ Order Placed Successfully");
  //
  //   int loyaltyPoints = 0;
  //   if (totalAmount >= 1000) {
  //     loyaltyPoints = 30;
  //   } else if (totalAmount >= 500) {
  //     loyaltyPoints = 15;
  //   } else if (totalAmount >= 200) {
  //     loyaltyPoints = 10;
  //   }
  //
  //   if (loyaltyPoints > 0) {
  //     // Fetch current loyalty points
  //     DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("users").doc(userId).get();
  //     int currentLoyalty = (userDoc.data() as Map<String, dynamic>)["Loyalty"] ?? 0;
  //     int updatedLoyalty = currentLoyalty + loyaltyPoints;
  //
  //     await FirebaseFirestore.instance
  //         .collection("users")
  //         .doc(userId)
  //         .update({"Loyalty": updatedLoyalty});
  //     print("🏆 Loyalty Points Updated: $updatedLoyalty");
  //
  //     // Show message with points earned
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //       content: Text("Order placed successfully! 🎉 You earned $loyaltyPoints Loyalty Points."),
  //       duration: Duration(seconds: 2),
  //     ));
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //       content: Text("Order placed successfully!"),
  //       duration: Duration(seconds: 2),
  //     ));
  //   }
  //
  //   // Clear Cart
  //   print("🧹 Clearing Cart...");
  //   for (var doc in cartSnapshot.docs) {
  //     await FirebaseFirestore.instance
  //         .collection("users")
  //         .doc(userId)
  //         .collection("Cart")
  //         .doc(doc.id)
  //         .delete();
  //     print("🛒 Deleted Cart Item: ${doc.id}");
  //   }
  //
  //   print("✅ Cart Cleared Successfully");
  //
  //   // Show Success Message & Navigate
  //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //     content: Text("Order placed successfully!"),
  //     duration: Duration(seconds: 2),
  //   ));
  //
  //   await Future.delayed(Duration(seconds: 1));
  //
  //   if (mounted) {
  //     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNav()));
  //   }
  // }

  void toggleLoyaltyPoints(bool? value) {
    if (value == null) return;
    setState(() {
      useLoyaltyPoints = value;
      appliedLoyalty = useLoyaltyPoints ? (loyalty > total + deliveryCharge ? total + deliveryCharge : loyalty) : 0;
    });
  }

  Future<void> placeOrder() async {
    print("🔍 placeOrder() Function Called");

    try {
      await getUserData();
      print("✅ User Data Fetched");

      if (!mounted) {
        print("⚠️ Widget is not mounted. Exiting...");
        return;
      }

      if (userId == null || wallet == null) {
        print("❌ User ID or Wallet is null");
        return;
      }

      print("✅ User ID Found: $userId");

      // 🔍 Fetch User Data Again to Print Wallet & Loyalty
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("users").doc(userId).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        String fetchedWallet = userData["Wallet"] ?? "0";
        int fetchedLoyalty = userData["Loyalty"] ?? 0;

        print("💰 Wallet Amount (Fetched): $fetchedWallet");
        print("🏆 Loyalty Points (Fetched): $fetchedLoyalty");
      } else {
        print("⚠️ User document does not exist in Firestore.");
      }

      int finalAmount = total + deliveryCharge - appliedLoyalty;
      if (finalAmount < 0) finalAmount = 0;

      if (useLoyaltyPoints) {
        await FirebaseFirestore.instance.collection("users").doc(userId).update({
          "Loyalty": 0,
        });
      }

      int walletAmount = int.tryParse(wallet!) ?? 0;
      // int totalAmount = total + deliveryCharge; // Include delivery charge
      print("💵 Total Amount with Delivery: $finalAmount");

      if (walletAmount < finalAmount) {
        print("❌ Insufficient Balance");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Insufficient balance! Please top up your wallet."),
          duration: Duration(seconds: 2),
        ));
        return;
      }

      // 🔍 Fetch Cart Items from Firestore
      print("📥 Fetching cart items...");
      QuerySnapshot cartSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("Cart")
          .get();
      print("✅ Cart items fetched");

      if (cartSnapshot.docs.isEmpty) {
        print("❌ Cart is Empty");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Your cart is empty!"),
          ));
        }
        return;
      }

      // 🔍 Convert Firestore docs to a list of items
      List<Map<String, dynamic>> cartItems =
      cartSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      print("🛒 Cart Items Found: ${cartItems.length}");

      // 🔍 Generate Order ID
      String orderId = FirebaseFirestore.instance.collection("Orders").doc().id;
      print("📌 Generated Order ID: $orderId");



      // 💳 Deduct Wallet Amount
      int remainingAmount = walletAmount - finalAmount;
      print("💳 Deducting Wallet... Remaining Balance: $remainingAmount");

      await FirebaseFirestore.instance.collection("users").doc(userId).update({
        "Wallet": remainingAmount.toString()
      });
      print("✅ Wallet Deducted Successfully");

      // 📦 Save Order to Firestore
      print("📤 Saving Order to Firestore...");
      await FirebaseFirestore.instance.collection("Orders").doc(orderId).set({
        "userId": userId,
        "totalAmount": finalAmount,
        "orderDate": Timestamp.now(),
        "items": cartItems,
        "address": widget.selectedAddress,
        "deliveryTime": widget.selectedDeliveryTime,
        "KitchenorderStatus": "Pending",
      });

      print("✅ Order Placed Successfully");

      // 🏆 Determine Loyalty Points Based on Total Amount
      int loyaltyPoints = 0;
      if (finalAmount >= 1000) {
        loyaltyPoints = 30;
      } else if (finalAmount >= 500) {
        loyaltyPoints = 15;
      } else if (finalAmount >= 200) {
        loyaltyPoints = 10;
      }
      print("🎯 Loyalty Points Calculated: $loyaltyPoints");

      if (loyaltyPoints > 0) {
        print("🔍 Fetching current loyalty points...");
        int currentLoyalty = userDoc.exists ? (userDoc["Loyalty"] ?? 0) : 0;

        int updatedLoyalty = currentLoyalty + loyaltyPoints;
        print("🏆 Updating Loyalty Points... New Total: $updatedLoyalty");

        await FirebaseFirestore.instance.collection("users").doc(userId).update({
          "Loyalty": updatedLoyalty
        });

        print("✅ Loyalty Points Updated Successfully");

        // Show message with points earned
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Order placed successfully! 🎉 You earned $loyaltyPoints Loyalty Points."),
          duration: Duration(seconds: 2),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Order placed successfully!"),
          duration: Duration(seconds: 2),
        ));
      }

      // 🧹 Clearing Cart
      print("🧹 Clearing Cart...");
      for (var doc in cartSnapshot.docs) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .collection("Cart")
            .doc(doc.id)
            .delete();
        print("🛒 Deleted Cart Item: ${doc.id}");
      }

      print("✅ Cart Cleared Successfully");

      await Future.delayed(Duration(seconds: 1));

      if (mounted) {
        print("🔄 Navigating to BottomNav...");
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNav()));
      }
    } catch (e, stackTrace) {
      print("❌ ERROR: $e");
      print("📝 StackTrace: $stackTrace");

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Something went wrong. Please try again."),
        duration: Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Order Summary")),
      body: RefreshIndicator(
        onRefresh: fetchCartItems,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Delivery Address:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(widget.selectedAddress, style: TextStyle(fontSize: 16)),
              SizedBox(height: 20),

              Text("Cart Items:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(
                child: cartItems.isEmpty
                    ? Center(child: Text("Your cart is empty!", style: TextStyle(fontSize: 16)))
                    : ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    var item = cartItems[index];
                    return Card(
                      child: ListTile(
                        leading: item['Image'] != null && item['Image'].isNotEmpty
                            ? Image.network(item['Image'], width: 50, height: 50, fit: BoxFit.cover)
                            : Icon(Icons.fastfood), // Fallback icon
                        title: Text(item['Name'] ?? 'Unknown Item'),
                        subtitle: Text("Category: ${item['FoodCategory']} \nQuantity: ${item['Quantity']}"),
                        trailing: Text("₹${item['Total']}"),
                      ),
                    );
                  },
                ),
              ),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Subtotal:", style: TextStyle(fontSize: 16)),
                  Text("₹$total", style: TextStyle(fontSize: 16)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Delivery Charge:", style: TextStyle(fontSize: 16)),
                  Text("₹$deliveryCharge", style: TextStyle(fontSize: 16)),
                ],
              ),
              CheckboxListTile(
                title: Text("Use Loyalty Points ($loyalty available)"),
                value: useLoyaltyPoints,
                onChanged: toggleLoyaltyPoints,
              ),
              if (useLoyaltyPoints) // Show only if loyalty is applied
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Discount (Loyalty Points):", style: TextStyle(fontSize: 16, color: Colors.green)),
                    Text("-₹$appliedLoyalty", style: TextStyle(fontSize: 16, color: Colors.green)),
                  ],
                ),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Amount:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    "₹${(total + deliveryCharge - appliedLoyalty).clamp(0, double.infinity)}", // Ensures total doesn't go negative
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              // Divider(),
              // Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              //   Text("Subtotal:", style: TextStyle(fontSize: 16)),
              //   Text("₹$total", style: TextStyle(fontSize: 16)),
              // ]),
              // Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              //   Text("Delivery Charge:", style: TextStyle(fontSize: 16)),
              //   Text("₹$deliveryCharge", style: TextStyle(fontSize: 16)),
              // ]),
              // CheckboxListTile(
              //   title: Text("Use Loyalty Points ($loyalty available)"),
              //   value: useLoyaltyPoints,
              //   onChanged: toggleLoyaltyPoints,
              // ),
              // Divider(),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Text("Total Amount:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              //     Text(
              //       "₹${(total + deliveryCharge - appliedLoyalty).clamp(0, double.infinity)}",
              //       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              //     ),
              //   ],
              // ),

              SizedBox(height: 20),Center(
                child: ElevatedButton(
                  onPressed: () => placeOrder(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white, // Text color
                    textStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Text("Confirm Order"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
