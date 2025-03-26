import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodapp/pages/address.dart';
import 'package:foodapp/pages/bottomnav.dart';
import 'package:foodapp/pages/healthyitems.dart';
import 'package:foodapp/pages/ordersummary.dart';
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
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();

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
        if (address is Map && address.containsKey('address')) {
          String humanReadable = address['address'] ?? 'Unknown';
          double latitude = (address['latitude'] as num?)?.toDouble() ?? 0.0;
          double longitude = (address['longitude'] as num?)?.toDouble() ?? 0.0;
          return '$humanReadable (Lat: $latitude, Lng: $longitude)';
        }
        return 'Unknown address'; // Fallback case
      }).toList();

      String? selectedAddress = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select an Address'),
            content: SingleChildScrollView( // Wrap in SingleChildScrollView
              child: Container(
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
      setState(() {
        selectedDeliveryTime = time;// Store the selected address
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderSummaryPage(
            selectedAddress: selectedAddress,
            selectedDeliveryTime: time,
          ),
        ),
      );
    }
  }

  Future<void> junkCheck(BuildContext context, String userId, VoidCallback onCheckout) async {
    print("🚀 Checkout button clicked! Checking for junk orders...");

    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final pastWeek = now.subtract(Duration(days: 7));

    final parentContext = context;

    try {
      // 🟢 Fetch Order History for the past 7 days
      QuerySnapshot orderSnapshot = await firestore
          .collection("order_history")
          .where("userId", isEqualTo: userId)
          .where("orderDate", isGreaterThanOrEqualTo: Timestamp.fromDate(pastWeek))
          .get();

      print("📦 Total orders in past 7 days: ${orderSnapshot.docs.length}");

      // 🟢 Count junk orders
      // int junkOrderCount = orderSnapshot.docs.where((doc) {
      //   final data = doc.data() as Map<String, dynamic>?; // Explicitly cast to Map
      //   if (data == null || !data.containsKey("items") || data["items"] == null) return false;
      //
      //   List<dynamic> items = data["items"]; // Cast to List
      //   return items.any((item) {
      //     if (item is Map<String, dynamic> && item.containsKey("FoodCategory")) {
      //       return item["FoodCategory"] == "Junk";
      //     }
      //     return false;
      //   });
      // }).length;
      int junkOrderCount = orderSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?; // Explicitly cast to Map
        if (data == null || !data.containsKey("items") || data["items"] == null || !data.containsKey("orderDate")) {
          return false;
        }

        List<dynamic> items = data["items"]; // Cast to List
        Timestamp orderTimestamp = data["orderDate"]; // Ensure orderDate exists
        DateTime orderDate = orderTimestamp.toDate();

        return orderDate.isAfter(pastWeek) && items.any((item) {
          if (item is Map<String, dynamic> && item.containsKey("FoodCategory")) {
            return item["FoodCategory"] == "Junk";
          }
          return false;
        });
      }).length;

      print("🚨 Junk orders found: $junkOrderCount");

      // 🟢 Fetch Cart Items
      QuerySnapshot cartItemsSnapshot = await firestore
          .collection("users")
          .doc(userId)
          .collection("Cart")
          .get();

      // 🟢 Check if ANY item in the cart is Junk
      bool hasJunkItem = cartItemsSnapshot.docs.any((doc) {
        final data = doc.data() as Map<String, dynamic>?; // Explicitly cast to Map
        if (data != null && data.containsKey("FoodCategory")) {
          return data["FoodCategory"] == "Junk";
        }
        return false;
      });

      if (junkOrderCount >= 2 && hasJunkItem) {
        print("Junk item found in cart. Showing warning...");

        if (!parentContext.mounted) return;

        showDialog(
          context: parentContext,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text("Junk Food Alert!"),
              content: Text("Your cart contains junk food. Consider choosing a healthier option!"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HealthyItems()), // Redirect to healthy options
                    );
                  },
                  child: Text("Choose Healthy"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    onCheckout(); // Allow checkout despite warning
                  },
                  child: Text("Order Anyways"),
                ),
              ],
            );
          },
        );
        return;
      }

      // ✅ No restriction, allow checkout
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
                  junkCheck(context, userId, () async {
                    await selectAddress(); // This will now navigate to OrderSummaryPage
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
