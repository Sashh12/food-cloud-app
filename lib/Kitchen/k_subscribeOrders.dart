import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VendorsSubscriptionOrders extends StatefulWidget {
  @override
  _VendorsSubscriptionOrdersState createState() => _VendorsSubscriptionOrdersState();
}

class _VendorsSubscriptionOrdersState extends State<VendorsSubscriptionOrders> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid; // Get the current user ID
  String? loggedInKitchenName;
  Stream<QuerySnapshot>? _subscriptionsStream;

  @override
  void initState() {
    super.initState();
    if (userId != null) {
      _fetchKitchenName(); // Fetch the kitchen name when the page loads
    }
  }

  // Fetch the kitchen name using the vendor's UID from Firebase Authentication
  Future<void> _fetchKitchenName() async {
    DocumentSnapshot kitchenDoc = await _firestore
        .collection('kitchens')
        .doc(userId)
        .get();

    if (kitchenDoc.exists) {
      setState(() {
        loggedInKitchenName = kitchenDoc['kitchenname']; // Save the kitchen name
      });

      // Now that we have the kitchen name, we can fetch the subscription orders for this kitchen
      _fetchSubscriptionOrders();
    }
  }

  // Fetch subscription orders where the kitchenName matches the logged-in kitchen name
  Future<void> _fetchSubscriptionOrders() async {
    if (loggedInKitchenName == null) return;

    _subscriptionsStream = _firestore
        .collection('subscription_Orders')
        .where('kitchenName', isEqualTo: loggedInKitchenName) // Filter orders by kitchen name
        .snapshots();
    setState(() {});
  }

  Future<void> _updateSubscriptionStatus(String subscribeOrderId, String newStatus) async {
    try {
      DocumentReference subscriptionRef = _firestore
          .collection('subscription_Orders') // Ensure correct collection
          .doc(subscribeOrderId); // Access the specific order document
      await subscriptionRef.update({'orderStatus': newStatus});
    } catch (e) {
      print("Error updating subscription status: $e");
    }
  }

  Widget allSubscriptionOrders() {
    return StreamBuilder<QuerySnapshot>(
      stream: _subscriptionsStream,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No subscription orders available'));
        }

        // Debug: Print document IDs and data for checking
        for (var doc in snapshot.data!.docs) {
          print('Document ID: ${doc.id}, Data: ${doc.data()}');
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: snapshot.data!.docs.length,
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data!.docs[index];
            final orderId = ds.id;

            // Cast to Map<String, dynamic> to access fields
            final Map<String, dynamic> data = ds.data() as Map<String, dynamic>;
            final orderDate = (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now();
            final day = data['day'] ?? 'N/A';
            final productName = data['productName'] ?? 'N/A';
            final price = data['price']?.toString() ?? '0';
            final lunchTime = data['lunchTime'] ?? 'N/A';
            final dinnerTime = data['dinnerTime'] ?? 'N/A';
            final currentStatus = data['orderStatus'] ?? 'Pending'; // Default to 'Pending'

            // Ensure valid status values
            const List<String> statusOptions = ['Pending', 'Completed', 'Cancelled'];
            final validCurrentStatus = statusOptions.contains(currentStatus) ? currentStatus : 'Pending';

            return Container(
              margin: EdgeInsets.all(8),
              child: Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black54, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order ID: $orderId', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Order Date: ${orderDate.toLocal()}'),
                      Text('Day: $day'),
                      Text('Product Name: $productName'),
                      Text('Lunch Time: $lunchTime'),
                      Text('Dinner Time: $dinnerTime'),
                      Text('Price: ₹$price', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 10.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                          DropdownButton<String>(
                            value: validCurrentStatus,
                            items: statusOptions.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null && newValue != validCurrentStatus) {
                                _updateSubscriptionStatus(orderId, newValue);
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 10.0),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subscription Orders'),
        centerTitle: true,
      ),
      body: allSubscriptionOrders(),
    );
  }
}
