import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VendorsOrders extends StatefulWidget {
  @override
  _VendorsOrdersState createState() => _VendorsOrdersState();
}

class _VendorsOrdersState extends State<VendorsOrders> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<QuerySnapshot>? _ordersStream;
  String? loggedInKitchenName;

  @override
  void initState() {
    super.initState();
    _fetchKitchenName();
  }

  /// Fetches the logged-in user's kitchen name and sets up the Firestore query
  void _fetchKitchenName() async {
    User? user = _auth.currentUser;

    if (user != null) {
      String kitchenId = user.uid;
      print("DEBUG: Logged-in user ID: $kitchenId");

      try {
        DocumentSnapshot kitchenDoc =
        await _firestore.collection('kitchens').doc(kitchenId).get();

        if (kitchenDoc.exists && kitchenDoc.data() != null) {
          String kitchenName =
          kitchenDoc['kitchenname'].toString().trim().toLowerCase();
          print("DEBUG: Retrieved kitchenname from kitchens collection: '$kitchenName'");

          setState(() {
            loggedInKitchenName = kitchenName;
            // Fetch all orders (since kitchenname is inside `items`)
            _ordersStream = _firestore.collection('Orders').snapshots();
          });
        } else {
          print("ERROR: No kitchen found for userId: $kitchenId");
        }
      } catch (e) {
        print("ERROR: Failed to fetch kitchenname - $e");
      }
    } else {
      print("ERROR: No user is logged in.");
    }
  }

  /// Updates the order status in Firestore
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('Orders').doc(orderId).update({
        'KitchenorderStatus': newStatus,
      });
      print("DEBUG: Updated order $orderId to status: $newStatus");
    } catch (e) {
      print("ERROR: Error updating order status - $e");
    }
  }

  /// Builds the orders list UI
  Widget allOrders() {
    return StreamBuilder<QuerySnapshot>(
      stream: _ordersStream,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print("ERROR: Firestore error - ${snapshot.error}");
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print("DEBUG: No orders found.");
          return Center(child: Text('No orders available'));
        }

        // 🔍 Filter orders where `items[].kitchenname` matches `loggedInKitchenName`
        final filteredOrders = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;

          if (data == null || !data.containsKey('items')) return false;

          List<dynamic> items = data['items'];
          return items.any((item) =>
          item is Map<String, dynamic> &&
              item.containsKey('kitchenname') &&
              item['kitchenname'].toString().trim().toLowerCase() ==
                  loggedInKitchenName);
        }).toList();

        if (filteredOrders.isEmpty) {
          print("DEBUG: No orders found for kitchenname: $loggedInKitchenName");
          return Center(child: Text('No orders available'));
        }

        print("DEBUG: Found ${filteredOrders.length} orders for kitchenname: $loggedInKitchenName");

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: filteredOrders.length,
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = filteredOrders[index];
            final orderId = ds.id;
            final orderDate = (ds['orderDate'] as Timestamp).toDate();
            final totalAmount = ds['totalAmount'];
            final userId = ds['userId'];
            final items = ds['items'] as List<dynamic>;

            final Map<String, dynamic> data = ds.data() as Map<String, dynamic>;
            final currentStatus = data['KitchenorderStatus'] ?? 'Pending';

            const List<String> statusOptions = [
              'Pending',
              'Preparing',
              'Out for Delivery',
              'Completed',
              'Cancelled'
            ];
            final validCurrentStatus =
            statusOptions.contains(currentStatus) ? currentStatus : 'Pending';

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
                      Text('UserId: ${userId}'),
                      Text('Order ID: $orderId',
                          style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Order Date: ${orderDate.toLocal()}'),
                      Text('Total Amount: ₹$totalAmount',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 10.0),
                      Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...items.map((item) {
                        return ListTile(
                          leading: Image.network(item['Image'],
                              width: 50, height: 50, fit: BoxFit.cover),
                          title: Text(item['Name']),
                          subtitle: Text(
                              'Quantity: ${item['Quantity']}, Total: ₹${item['Total']}'),
                        );
                      }).toList(),
                      SizedBox(height: 10.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order Status:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          DropdownButton<String>(
                            value: validCurrentStatus,
                            items: statusOptions
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null &&
                                  newValue != validCurrentStatus) {
                                _updateOrderStatus(orderId, newValue);
                              }
                            },
                          ),
                        ],
                      ),
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
        title: Text('Orders'),
        centerTitle: true,
      ),
      body: allOrders(),
    );
  }
}
