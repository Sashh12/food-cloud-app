import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VendorsOrders extends StatefulWidget {
  @override
  _VendorsOrdersState createState() => _VendorsOrdersState();
}

class _VendorsOrdersState extends State<VendorsOrders> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Stream<QuerySnapshot>? _ordersStream;

  @override
  void initState() {
    super.initState();
    _ordersStream = _firestore.collection('orders').snapshots();
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      DocumentReference orderRef = _firestore.collection('orders').doc(orderId);
      await orderRef.update({'orderStatus': newStatus});
    } catch (e) {
      print("Error updating order status: $e");
    }
  }

  // Future<void> _updateDeliveryStatus(String orderId, String newDeliveryStatus) async {
  //   try {
  //     DocumentReference orderRef = _firestore.collection('orders').doc(orderId);
  //     await orderRef.update({'deliveryStatus': newDeliveryStatus});
  //   } catch (e) {
  //     print("Error updating delivery status: $e");
  //   }
  // }

  Widget allOrders() {
    return StreamBuilder<QuerySnapshot>(
      stream: _ordersStream,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No orders available'));
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: snapshot.data!.docs.length,
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data!.docs[index];
            final orderId = ds.id;
            final orderDate = (ds['orderDate'] as Timestamp).toDate();
            final totalAmount = ds['totalAmount'];
            final userId = ds['userId'];
            final items = ds['items'] as List<dynamic>;

            // Cast to Map<String, dynamic> to access fields
            final Map<String, dynamic> data = ds.data() as Map<String, dynamic>;
            final currentStatus = data['orderStatus'] ?? 'Pending'; // Default to 'Pending'
            // final currentDeliveryStatus = data['deliveryStatus'] ?? 'Order Accepted'; // Default to 'Order Accepted'

            // Ensure valid status values
            const List<String> statusOptions = ['Pending', 'Preparing', 'Completed', 'Out for Delivery', 'Cancelled'];
            final validCurrentStatus = statusOptions.contains(currentStatus) ? currentStatus : 'Pending';

            // Ensure valid delivery status values
            // const List<String> deliveryStatusOptions = ['Order Accepted', 'Ready for Delivery'];
            // final validCurrentDeliveryStatus = deliveryStatusOptions.contains(currentDeliveryStatus) ? currentDeliveryStatus : 'Order Accepted';

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
                      Text('Order ID: $orderId', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Order Date: ${orderDate.toLocal()}'),
                      Text('Total Amount: ₹$totalAmount', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 10.0),
                      Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...items.map((item) {
                        return ListTile(
                          leading: Image.network(item['Image'], width: 50, height: 50, fit: BoxFit.cover),
                          title: Text(item['Name']),
                          subtitle: Text('Quantity: ${item['Quantity']}, Total: ₹${item['Total']}'),
                        );
                      }).toList(),
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
                                _updateOrderStatus(orderId, newValue);
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 10.0),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //   children: [
                      //     Text('Delivery Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                      //     DropdownButton<String>(
                      //       value: validCurrentDeliveryStatus,
                      //       items: deliveryStatusOptions.map<DropdownMenuItem<String>>((String value) {
                      //         return DropdownMenuItem<String>(
                      //           value: value,
                      //           child: Text(value),
                      //         );
                      //       }).toList(),
                      //       onChanged: (String? newValue) {
                      //         if (newValue != null && newValue != validCurrentDeliveryStatus) {
                      //           _updateDeliveryStatus(orderId, newValue);
                      //         }
                      //       },
                      //     ),
                      //   ],
                      // ),
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
