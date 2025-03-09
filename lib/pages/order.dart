import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodapp/pages/address.dart';
import 'package:foodapp/pages/bottomnav.dart';
import 'package:foodapp/pages/healthyitems.dart';
import 'package:foodapp/service/database.dart';
import 'package:foodapp/widget/widget_support.dart';
import 'dart:async';

class Order extends StatefulWidget {
  const Order({super.key});

  @override
  State<Order> createState() => _OrderState();
}

class _OrderState extends State<Order> {
  String? id, wallet;
  int total = 0, amount2 = 0;
  Stream? foodStream;
  String? selectedDeliveryTime;
  String? selectedAddress;

  @override
  void initState() {
    super.initState();
    ontheload();
    startTimer();
    print("🚀 Starting Order Status Listener...");
    startOrderStatusListener();
  }

  void startTimer() {
    Timer(Duration(seconds: 2), () {
      if (!mounted) return; // Prevent setState after dispose
      setState(() {
        amount2 = total;
      });
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
          // Reset total before calculating
          total = 0;

          return ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: snapshot.data.docs.length,
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              itemBuilder: (context, index) {
                DocumentSnapshot ds = snapshot.data.docs[index];
                total += int.parse(ds["Total"]); // Add each item total
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
                              child: Center(child: Text(ds["Quantity"]))),
                          SizedBox(width: 10.0),
                          ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: Image.network(ds["Image"], height: 90, width: 90, fit: BoxFit.cover)),
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
                          IconButton(
                            icon: Icon(Icons.cancel, color: Colors.black),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(id)
                                  .collection("Cart")
                                  .doc(ds.id)
                                  .delete();
                              setState(() {});
                            },
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
    print("🔍 placeOrder() Function Called");

    // Check if the widget is still mounted
    if (!mounted) return;

    if (id != null && wallet != null) {
      print("✅ User ID Found: $id");
      print("💰 Wallet Amount: $wallet");

      int walletAmount = int.parse(wallet!);
      int totalAmount = total + 40; // Delivery charge included
      print("💵 Total Amount with Delivery: $totalAmount");

      // Check if the wallet has sufficient balance
      if (walletAmount < totalAmount) {
        print("Insufficient Balance");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Insufficient balance! Please top up your wallet."),
          duration: Duration(seconds: 2),
        ));
        return;
      }

      // Deduct Wallet Amount
      int remainingAmount = walletAmount - totalAmount;
      print("💳 Deducting Wallet... Remaining Amount: $remainingAmount");

      await FirebaseFirestore.instance
          .collection("users")
          .doc(id)
          .update({"Wallet": remainingAmount.toString()});
      print("✅ Wallet Deducted Successfully");

      // Fetch Cart Items
      var cartItems = await FirebaseFirestore.instance
          .collection("users")
          .doc(id)
          .collection("Cart")
          .get();

      if (cartItems.docs.isEmpty) {
        print("Cart is Empty");
        if (mounted) { // Check if still mounted before showing SnackBar
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Your cart is empty!"),
          ));
        }
        return;
      }

      print("🛒 Cart Items Found: ${cartItems.docs.length}");

      // Generate Order ID
      String orderId = FirebaseFirestore.instance.collection("Orders").doc().id;
      print("Generated Order ID: $orderId");

      // Place Order
      await FirebaseFirestore.instance.collection("Orders").doc(orderId).set({
        "userId": id,
        "totalAmount": totalAmount,
        "orderDate": Timestamp.now(),
        "items": cartItems.docs.map((doc) => doc.data()).toList(),
        "address": selectedAddress,
        "deliveryTime": selectedDeliveryTime ?? "Not Available",
        "KitchenorderStatus": "Pending",
      });

      print("✅ Order Placed Successfully in Orders Collection");

      // Clear Cart
      print("🧹 Clearing Cart Items...");
      for (var doc in cartItems.docs) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(id)
            .collection("Cart")
            .doc(doc.id)
            .delete();
        print("🛒 Cart Item Deleted: ${doc.id}");
      }

      print("✅ Cart Cleared Successfully");

      // Show success message and navigate to BottomNav
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Order placed successfully!"),
        duration: Duration(seconds: 2),
      ));

      await Future.delayed(Duration(seconds: 1));

      if (mounted) { // Check if still mounted before navigating
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => BottomNav()));
      }
    }
  }

  void startOrderStatusListener() {
    FirebaseFirestore.instance.collection("Orders").snapshots().listen((snapshot) {
      print("🔄 Checking for active orders...");

      if (snapshot.docs.isEmpty) {
        print("🚫 No orders found.");
        return;
      }

      print("📦 Found ${snapshot.docs.length} orders.");

      for (var order in snapshot.docs) {
        String orderId = order.id;
        String kitchenOrderStatus = order["KitchenorderStatus"];

        print("🔍 Checking Order ID: $orderId, Status: $kitchenOrderStatus");

        if (kitchenOrderStatus == "Completed") {
          print("✅ Order $orderId is completed. Moving to history...");

          moveToOrderHistory(orderId, order["userId"], order.data()).catchError((e) {
            print("❌ Error moving order $orderId to history: $e");
          });
        }
      }
    }, onError: (error) {
      print("❌ Firestore Listener Error: $error");
    });
  }

  Future<void> moveToOrderHistory(String orderId, String userId, Map<String, dynamic> orderData) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Reference to the order document
    DocumentReference orderRef = firestore.collection('orders').doc(orderId);

    // Reference to order history collection
    CollectionReference orderHistoryRef = firestore.collection('order_history');

    print("🚚 Moving Order to History Immediately: $orderId");

    try {
      // Log the order data being moved
      print("📜 Order Data: ${orderData.toString()}");

      // Move order to history
      await orderHistoryRef.doc(orderId).set(orderData);
      print("✅ Order successfully moved to Order History!");

      // Remove order from the 'orders' collection immediately
      await orderRef.delete();
      print("🗑️ Order deleted from Active Orders!");

    } catch (e) {
      print("❌ Error moving order to history: $e");
    }
  }


  Future<void> selectAddress() async {
    User? user = FirebaseAuth.instance.currentUser;
    String? userId = user?.uid;

    if (userId != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'addresses': [],
        });
        userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      }

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      if (userData == null || !userData.containsKey('addresses')) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'addresses': [],
        }, SetOptions(merge: true));

        userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        userData = userDoc.data() as Map<String, dynamic>?; // Refresh data after set
      }

      List<dynamic> addresses = userData?['addresses'] ?? [];

      // Convert addresses to human-readable format
      List<String> displayAddresses = addresses.map((address) {
        if (address is Map) {
          String humanReadable = address['address'] ?? '';
          double latitude = address['latitude'] ?? 0.0;
          double longitude = address['longitude'] ?? 0.0;
          return '$humanReadable (Lat: $latitude, Lng: $longitude)';
        }
        return 'Unknown address'; // Fallback case
      }).toList();

      String? selectedAddress = await showDialog<String>( // Show addresses in a dialog
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
                      itemCount: displayAddresses.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(displayAddresses[index]),
                          onTap: () {
                            Navigator.of(context).pop(displayAddresses[index]);
                          },
                        );
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddAddressScreen()),
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
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
            ],
          );
        },
      );

      if (selectedAddress != null) {
        setState(() {
          this.selectedAddress = selectedAddress; // Store the selected address
        });
        // Show delivery time selection dialog
        await selectDeliveryTime(selectedAddress);
      }
    }
  }


  Future<void> selectDeliveryTime(String selectedAddress) async {
    String? time = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Delivery Time'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Now'),
                onTap: () {
                  Navigator.of(context).pop('Now');
                },
              ),
              ListTile(
                title: Text('Select Custom Time'),
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    String formattedTime = pickedTime.format(context);
                    Navigator.of(context).pop(formattedTime);
                  }
                },
              ),
            ],
          ),
        );
      },
    );

    if (time != null) {
      selectedDeliveryTime = time;
      await placeOrder(selectedAddress);
    }
  }


  void checkAndProceedCheckout(BuildContext context, String userId, VoidCallback onCheckout) async {
    print("🚀 Checkout button clicked! Checking for junk orders...");

    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final pastWeek = now.subtract(Duration(days: 7));

    // Store parent context before async operations
    final parentContext = context;

    try {
      QuerySnapshot orderSnapshot = await firestore
          .collection("order_history")
          .where("userId", isEqualTo: userId)
          .where("orderDate", isGreaterThanOrEqualTo: Timestamp.fromDate(pastWeek))
          .get();

      print("📦 Total orders in past 7 days: ${orderSnapshot.docs.length}");

      int junkOrderCount = orderSnapshot.docs.where((doc) {
        List<dynamic> items = doc["items"];
        return items.any((item) => item["FoodCategory"] == "Junk");
      }).length;

      print("🚨 Junk orders found: $junkOrderCount");

      if (junkOrderCount > 1) {
        print("🚫 Too many Junk orders. Showing alert...");

        // Ensure context is still valid
        if (!parentContext.mounted) return;

        showDialog(
          context: parentContext, // Use stored parent context
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text("Too Much Junk Food!"),
              content: Text("You've ordered junk food more than 2 times in the last 7 days. Try something healthy!"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Close the dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HealthyItems()), // Navigate to HealthyItems page
                    );
                  },
                  child: Text("OK"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    onCheckout();
                  },
                  child: Text("Order Anyways"),
                ),
              ],
            );
          },
        );
        return; // Prevent immediate checkout
      }

      print("✅ No junk order restriction! Proceeding to checkout...");
      onCheckout();

    } catch (e) {
      print("❌ Error checking orders: $e");

      if (!parentContext.mounted) return;

      ScaffoldMessenger.of(parentContext).showSnackBar(SnackBar(
        content: Text("Error checking orders. Please try again."),
      ));
    }
  }


  @override
  Widget build(BuildContext context) {
    bool isCartEmpty = total == 0; // Check if the cart is empty

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Subtotal", style: AppWidget.BoldTextFieldStyle()),
                      Text("\₹ $total", style: AppWidget.SemiBoldFieldStyle()),
                    ],
                  ),
                  SizedBox(height: 5.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Delivery Price", style: AppWidget.normalText()),
                      Text("\₹ 40", style: AppWidget.SemiBoldFieldStyle()),
                    ],
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total Price", style: AppWidget.BoldTextFieldStyle()),
                      Text("\₹ ${total + 40}", style: AppWidget.SemiBoldFieldStyle()), // Adding delivery price
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.0),
            GestureDetector(
              onTap: isCartEmpty
                  ? null
                  : () async {
                User? user = FirebaseAuth.instance.currentUser;
                String? userId = user?.uid;

                if (userId != null) {
                  checkAndProceedCheckout(context, userId, () async {
                    // Proceed only after junk check passes
                    await selectAddress(); // Now select address

                    if (selectedAddress != null) {
                      placeOrder(selectedAddress!);
                    } else {
                      print("Error: Address not selected");
                    }
                  });
                } else {
                  print("Error: User ID is null");
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: isCartEmpty ? Colors.grey : Colors.black,
                    borderRadius: BorderRadius.circular(10)),
                margin: EdgeInsets.only(left: 20.0, right: 20.0, bottom: 8.0),
                child: Center(
                    child: Text(
                      "Checkout",
                      style: TextStyle(
                          color: isCartEmpty ? Colors.black38 : Colors.white,
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold),
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
