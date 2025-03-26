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
  int total = 0;
  int deliveryCharge = 40; // Example delivery charge

  @override
  void initState() {
    super.initState();
    fetchCartItems();
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
    }

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

  Future<void> placeOrder() async {
    print("🔍 placeOrder() Function Called");

    await getUserData();

    if (!mounted) return; // Ensure widget is still mounted
    if (userId == null || wallet == null) {
      print("❌ User ID or Wallet is null");
      return;
    }

    print("✅ User ID Found: $userId");
    print("💰 Wallet Amount: $wallet");

    int walletAmount = int.tryParse(wallet!) ?? 0;
    int totalAmount = total + deliveryCharge; // Include delivery charge
    print("💵 Total Amount with Delivery: $totalAmount");

    if (walletAmount < totalAmount) {
      print("❌ Insufficient Balance");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Insufficient balance! Please top up your wallet."),
        duration: Duration(seconds: 2),
      ));
      return;
    }

    // Fetch Cart Items from Firestore
    QuerySnapshot cartSnapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("Cart")
        .get();

    if (cartSnapshot.docs.isEmpty) {
      print("❌ Cart is Empty");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Your cart is empty!"),
        ));
      }
      return;
    }

    // Convert Firestore docs to a list of items
    List<Map<String, dynamic>> cartItems = cartSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    print("🛒 Cart Items Found: ${cartItems.length}");

    // Generate Order ID
    String orderId = FirebaseFirestore.instance.collection("Orders").doc().id;
    print("📌 Generated Order ID: $orderId");

    // Deduct Wallet Amount
    int remainingAmount = walletAmount - totalAmount;
    print("💳 Deducting Wallet... Remaining Balance: $remainingAmount");

    await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .update({"Wallet": remainingAmount.toString()});
    print("✅ Wallet Deducted Successfully");

    // Save Order to Firestore
    await FirebaseFirestore.instance.collection("Orders").doc(orderId).set({
      "userId": userId,
      "totalAmount": totalAmount,
      "orderDate": Timestamp.now(),
      "items": cartItems,
      "address": widget.selectedAddress,
      "deliveryTime": widget.selectedDeliveryTime,
      "KitchenorderStatus": "Pending",
    });

    print("✅ Order Placed Successfully");

    // Clear Cart
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

    // Show Success Message & Navigate
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Order placed successfully!"),
      duration: Duration(seconds: 2),
    ));

    await Future.delayed(Duration(seconds: 1));

    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNav()));
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
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text("Subtotal:", style: TextStyle(fontSize: 16)),
                Text("₹$total", style: TextStyle(fontSize: 16)),
              ]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text("Delivery Charge:", style: TextStyle(fontSize: 16)),
                Text("₹$deliveryCharge", style: TextStyle(fontSize: 16)),
              ]),
              Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text("Total Amount:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("₹${total + deliveryCharge}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ]),

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
