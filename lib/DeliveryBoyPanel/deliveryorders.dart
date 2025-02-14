import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

import 'package:foodapp/DeliveryBoyPanel/completed_orders.dart';

class DeliveryOrders extends StatefulWidget {
  @override
  _DeliveryOrdersState createState() => _DeliveryOrdersState();
}

class _DeliveryOrdersState extends State<DeliveryOrders> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Stream<QuerySnapshot>? _ordersStream;

  @override
  void initState() {
    super.initState();
    _ordersStream = _firestore
        .collection('orders')
        .where('KitchenorderStatus', isEqualTo: 'Out for Delivery')
        .where('assignedDeliveryGuy', isNull: true)
        .snapshots();
  }

  Future<void> _updateDeliveryStatus(String orderId, String newDeliveryStatus, Map<String, dynamic> orderData) async {
    try {
      DocumentReference orderRef = _firestore.collection('orders').doc(orderId);
      await orderRef.update({'deliveryStatus': newDeliveryStatus});

      if (newDeliveryStatus == 'Delivered') {
        Timer(Duration(minutes: 2), () async {
          try {
            // Move to order history
            DocumentReference orderHistoryRef = _firestore
                .collection('orderHistory')
                .doc(orderData['userId'])
                .collection('orders')
                .doc(orderId);
            await orderHistoryRef.set(orderData);

            // Delete from orders collection
            await orderRef.delete();
          } catch (e) {
            print("Error moving order to history: $e");
          }
        });
      }
    } catch (e) {
      print("Error updating delivery status: $e");
    }
  }

  Future<void> _assignOrderToDeliveryGuy(String orderId) async {
    try {
      QuerySnapshot deliveryGuysSnapshot = await _firestore.collection('delivery_boys').get();
      List<DocumentSnapshot> deliveryGuys = deliveryGuysSnapshot.docs;

      if (deliveryGuys.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No delivery guys available')));
        return;
      }

      DocumentSnapshot selectedGuy = deliveryGuys[Random().nextInt(deliveryGuys.length)];
      final deliveryGuyId = selectedGuy.id;
      final deliveryGuyName = selectedGuy['name'];

      bool accepted = await _showDeliveryAlert(deliveryGuyName, orderId);

      if (accepted) {
        await _firestore.collection('orders').doc(orderId).update({
          'assignedDeliveryGuy': deliveryGuyId,
          'deliveryStatus': 'Accepted by $deliveryGuyName'
        });

        setState(() {});
      } else {
        deliveryGuys.remove(selectedGuy);
        if (deliveryGuys.isNotEmpty) {
          _assignOrderToDeliveryGuy(orderId);
        }
      }
    } catch (e) {
      print("Error assigning order to delivery guy: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error assigning order')));
    }
  }

  Future<bool> _showDeliveryAlert(String deliveryGuyName, String orderId) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("New Delivery Assignment"),
          content: Text("$deliveryGuyName, you have been assigned a new order (ID: $orderId). Do you accept?"),
          actions: <Widget>[
            TextButton(child: Text("Reject"), onPressed: () => Navigator.of(context).pop(false)),
            TextButton(child: Text("Accept"), onPressed: () => Navigator.of(context).pop(true)),
          ],
        );
      },
    ) ?? false;
  }

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

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: snapshot.data!.docs.length,
                shrinkWrap: true,
                scrollDirection: Axis.vertical,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data!.docs[index];
                  final orderId = ds.id;
                  final orderDate = (ds['orderDate'] as Timestamp).toDate();
                  final totalAmount = ds['totalAmount'];
                  final items = ds['items'] as List<dynamic>;
                  final Map<String, dynamic> data = ds.data() as Map<String, dynamic>;
                  final currentDeliveryStatus = data['deliveryStatus'] ?? 'Order Accepted';
                  final kitchenStatus = data['KitchenorderStatus'] ?? 'Pending';
                  final assignedDeliveryGuy = data['assignedDeliveryGuy'] ?? null;

                  bool isPendingAssignment = (kitchenStatus == 'Out for Delivery' && assignedDeliveryGuy == null);
                  bool showDeliveryStatusDropdown = assignedDeliveryGuy != null;

                  const List<String> deliveryStatusOptions = ['Order Picked', 'Out for Delivery', 'On the Way', 'Delivered'];
                  final validCurrentDeliveryStatus = deliveryStatusOptions.contains(currentDeliveryStatus)
                      ? currentDeliveryStatus
                      : deliveryStatusOptions.first;

                  return Container(
                    margin: EdgeInsets.all(10),
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
                            Text('Total Amount: ₹$totalAmount', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 10.0),
                            Text('Kitchen Status: $kitchenStatus', style: TextStyle(fontWeight: FontWeight.bold)),
                            if (showDeliveryStatusDropdown)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Delivery Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  DropdownButton<String>(
                                    value: validCurrentDeliveryStatus,
                                    items: deliveryStatusOptions.map<DropdownMenuItem<String>>((String value) {
                                      return DropdownMenuItem<String>(value: value, child: Text(value));
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null && newValue != validCurrentDeliveryStatus) {
                                        _updateDeliveryStatus(orderId, newValue, data);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            if (isPendingAssignment)
                              ElevatedButton(
                                onPressed: () {
                                  _assignOrderToDeliveryGuy(orderId);
                                },
                                child: Text('Accept Order for Delivery'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CompletedOrders()));
              },
              child: Text("Show Completed Orders"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Delivery Orders'), centerTitle: true),
      body: allOrders(),
    );
  }
}
