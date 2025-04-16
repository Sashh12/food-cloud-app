import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:foodapp/DeliveryBoyPanel/assigneddelivery.dart';
import 'package:location/location.dart' as loc;
import 'dart:async';
import 'dart:math';

import 'package:foodapp/DeliveryBoyPanel/completed_orders.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
// import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

class DeliveryOrders extends StatefulWidget {
  @override
  _DeliveryOrdersState createState() => _DeliveryOrdersState();
}

class _DeliveryOrdersState extends State<DeliveryOrders> {
  loc.Location location = loc.Location();
  double clatitude = 0;
  double clongitude = 0;
  bool isDeliveryStarted =false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Stream<QuerySnapshot>? _ordersStream;

  @override
  void initState() {
    super.initState();
    getLocation();
    _checkAndRequestLocationPermissions();
    print("Initializing DeliveryOrders...");
    _ordersStream = _firestore
        .collection('Orders')
        .where('KitchenorderStatus', isEqualTo: 'Out for Delivery')
        .snapshots();

    print("Orders stream initialized with 'Out for Delivery' & 'assignedDeliveryGuy == null'");

  }

  Future<void> _updateDeliveryStatus(String orderId, String newDeliveryStatus, Map<String, dynamic> orderData) async {
    print("Updating delivery status for orderId: $orderId to $newDeliveryStatus");
    try {
      DocumentReference orderRef = _firestore.collection('Orders').doc(orderId);
      await orderRef.update({'deliveryStatus': newDeliveryStatus});
      print("Delivery status updated successfully");

      if (newDeliveryStatus == 'Delivered') {
        print("Setting 2-minute timer to move order to history...");
        Timer(Duration(seconds: 5), () async {
          try {
            print("Timer completed. Moving order to order_history...");
            DocumentReference orderHistoryRef = _firestore.collection('order_history').doc(orderId);
            await orderHistoryRef.set(orderData);
            print("Order moved to order_history");

            await orderRef.delete();
            print("Original order deleted from Orders collection");
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
    print("Attempting to assign orderId: $orderId to a delivery guy");
    try {
      QuerySnapshot deliveryGuysSnapshot = await _firestore.collection('delivery_boys').get();
      List<DocumentSnapshot> deliveryGuys = deliveryGuysSnapshot.docs;
      print("Fetched ${deliveryGuys.length} delivery guys");

      if (deliveryGuys.isEmpty) {
        print("No delivery guys available");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No delivery guys available')));
        return;
      }

      DocumentSnapshot selectedGuy = deliveryGuys[Random().nextInt(deliveryGuys.length)];
      final deliveryGuyId = selectedGuy.id;
      final deliveryGuyName = selectedGuy['name'];

      print("Selected delivery guy: $deliveryGuyName ($deliveryGuyId)");

      bool accepted = await _showDeliveryAlert(deliveryGuyName, orderId);
      print("Delivery guy response: ${accepted ? 'Accepted' : 'Rejected'}");

      if (accepted) {
        await _firestore.collection('Orders').doc(orderId).update({
          'assignedDeliveryGuy': deliveryGuyId,
          'deliveryStatus': 'Accepted by $deliveryGuyName',
        });
        // Navigate to MyDeliveriesPage
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => MyDeliveriesPage(deliveryGuyId: deliveryGuyId),
        //   ),
        // );
        print("Order updated with assigned delivery guy");

        setState(() {});
      } else {
        print("Delivery guy rejected. Trying next one...");
        deliveryGuys.remove(selectedGuy);
        if (deliveryGuys.isNotEmpty) {
          _assignOrderToDeliveryGuy(orderId);
        } else {
          print("No more delivery guys left to assign");
        }
      }
    } catch (e) {
      print("Error assigning order to delivery guy: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error assigning order')));
    }
  }

  Future<bool> _showDeliveryAlert(String deliveryGuyName, String orderId) async {
    print("Showing alert to delivery guy: $deliveryGuyName for order $orderId");
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

  void _extractLatLngFromAddress(String address) {
    final regex = RegExp(r'Lat:\s*(-?\d+\.\d+),\s*Lng:\s*(-?\d+\.\d+)');
    final match = regex.firstMatch(address);
    if (match != null) {
      setState(() {
        clatitude = double.parse(match.group(1)!);
        clongitude = double.parse(match.group(2)!);
      });
      print("Extracted latitude: $clatitude, longitude: $clongitude");
    } else {
      print("No coordinates found in address");
    }
  }

  // Future<void> _startDelivery(String orderId) async {
  //   print("STARTING delivery process for orderId: $orderId");
  //
  //   final permissionGranted = await _checkAndRequestLocationPermissions();
  //   if (!permissionGranted) {
  //     print("❌ Cannot start delivery: Required permissions not granted");
  //     return;
  //   }
  //
  //   setState(() {
  //     isDeliveryStarted = true;
  //   });
  //
  //   if (clatitude != 0.0 && clongitude != 0.0) {
  //     print("Using extracted lat/lng - lat: $clatitude, lng: $clongitude");
  //
  //     _subscribeToLocationChanges(orderId);
  //     await addOrderTracking(orderId, clatitude, clongitude);
  //     print("Initial order tracking added for $orderId");
  //   } else {
  //     print("❌ Invalid lat/lng detected. Please extract address first.");
  //   }
  // }

  Future<void> _startDelivery(String orderId) async {
    print("STARTING delivery process for orderId: $orderId");

    // Request both location and foreground service permissions
    final locationPermissionsGranted = await _checkAndRequestLocationPermissions();
    final foregroundServiceGranted = await _requestForegroundServicePermissions();

    if (!locationPermissionsGranted || !foregroundServiceGranted) {
      print("❌ Cannot start delivery: Required permissions not granted");
      return;
    }

    setState(() {
      isDeliveryStarted = true;
    });

    if (clatitude != 0.0 && clongitude != 0.0) {
      print("Using extracted lat/lng - lat: $clatitude, lng: $clongitude");

      _subscribeToLocationChanges(orderId);  // This enables background mode
      await addOrderTracking(orderId, clatitude, clongitude);
      print("Initial order tracking added for $orderId");
    } else {
      print("❌ Invalid lat/lng detected. Please extract address first.");
    }
  }

  Future<void> _subscribeToLocationChanges(String orderId) async {
    print("🛰️ Subscribing to location changes for orderId: $orderId");

    try {
      // 👇 This sets the persistent notification required for FGS
      await location.changeNotificationOptions(
        title: "Delivery Tracking Enabled",
        subtitle: "Location tracking in progress",
        description: "App is tracking your delivery in real-time",
        iconName: "ic_launcher", // Ensure this icon exists in android/app/src/main/res/drawable
      );

      await location.enableBackgroundMode(enable: true);
      print("✅ Background mode enabled");

      location.onLocationChanged.listen((loc.LocationData currentLocation) {
        if (currentLocation == null) {
          print("⚠️ Received null LocationData");
          return;
        }

        double currentLat = currentLocation.latitude ?? -1;
        double currentLng = currentLocation.longitude ?? -1;

        print('📍 onLocationChanged fired');
        print('🧭 Extracted currentLat: $currentLat, currentLng: $currentLng');

        if (currentLat != -1 && currentLng != -1) {
          updateOrderLocation(orderId, currentLat, currentLng);
        } else {
          print("⚠️ Skipping update due to invalid coordinates: $currentLat, $currentLng");
        }
      });
    } catch (e) {
      print("❌ Error subscribing to location updates: $e");
    }
  }

  Future<void> addOrderTracking(String orderId, double currentLat, double currentLng) async {
    print("Adding initial tracking to Firestore for $orderId");

    try {
      await FirebaseFirestore.instance.collection("OrderTracking").doc(orderId).set({
        'orderId': orderId,
        'latitude': currentLat,
        'longitude': currentLng,
      });
      print("✅ Order tracking saved to Firestore");
    } catch (e) {
      print("❌ Error adding order tracking information: $e");
    }
  }

  Future<void> updateOrderLocation(String orderId, double newLatitude, double newLongitude) async {
    print("🔄 Updating order location for orderId: $orderId");

    if (orderId.isEmpty) {
      print("❗ orderId is empty. Cannot update Firestore.");
      return;
    }

    try {
      final DocumentSnapshot orderTrackingDoc = await FirebaseFirestore.instance
          .collection("OrderTracking")
          .doc(orderId)
          .get();

      if (orderTrackingDoc.exists) {
        print("📄 Order tracking document found. Updating...");

        await FirebaseFirestore.instance.collection("OrderTracking").doc(orderId).update({
          "latitude": newLatitude,  // use lowercase
          "longitude": newLongitude,
        });

        print("✅ Order location updated: $newLatitude, $newLongitude");
      } else {
        print("⚠️ No tracking doc found for $orderId. Creating new document...");
        await addOrderTracking(orderId, newLatitude, newLongitude);
      }
    } catch (e) {
      print("❌ Error updating order location: $e");
    }
  }

  Future<void> getLocation() async {
    print("🔍 Attempting to get current location");

    try {
      bool serviceEnabled = await loc.Location().serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await loc.Location().requestService();
        if (!serviceEnabled) {
          print("❌ Location service still disabled. Aborting.");
          return;
        }
      }

      loc.PermissionStatus permissionGranted = await loc.Location().hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await loc.Location().requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) {
          print("❌ Permission not granted. Aborting.");
          return;
        }
      }

      if (permissionGranted == loc.PermissionStatus.deniedForever) {
        print("🔐 Background location permission is denied forever. Please enable it in settings.");
        return;
      }

      loc.LocationData locationData = await loc.Location().getLocation();
      print('✅ Current Location: ${locationData.latitude}, ${locationData.longitude}');
    } catch (e) {
      print("❌ Error getting location: $e");
    }
  }


  Future<bool> _checkAndRequestLocationPermissions() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        print("❌ Location service still disabled");
        return false;
      }
    }

    var permission = await location.hasPermission();
    if (permission == loc.PermissionStatus.denied) {
      permission = await location.requestPermission();
    }

    if (permission == loc.PermissionStatus.deniedForever) {
      print("🔒 Location permission permanently denied. Ask user to enable from settings.");
      return false;
    }

    if (permission != loc.PermissionStatus.granted) {
      print("❌ Location permission not granted");
      return false;
    }

    return true;
  }

  Future<bool> _requestForegroundServicePermissions() async {
    final status1 = await perm.Permission.location.request();
    final status2 = await perm.Permission.locationAlways.request();
    // final status3 = await perm.Permission.foregroundService.request();

    final allGranted = status1.isGranted && status2.isGranted;
    if (!allGranted) {
      print("❌ Permissions not granted -> location: $status1, background: $status2, FGS:");
    }

    return allGranted;
  }




  Widget allOrders() {
    print("Building allOrders widget...");

    return StreamBuilder<QuerySnapshot>(
      stream: _ordersStream,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          print("Orders stream is still loading...");
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print("Orders stream has error: ${snapshot.error}");
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print("Orders stream returned empty data");
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(child: Text('No orders available')),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  print("Navigating to Completed Orders");
                  Navigator.push(context, MaterialPageRoute(builder: (context) => CompletedOrders()));
                },
                child: Text("Show Completed Orders"),
              ),
            ],
          );
        }

        print("Rendering ${snapshot.data!.docs.length} orders");

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data!.docs[index];
                  final orderId = ds.id;
                  final orderDate = (ds['orderDate'] as Timestamp).toDate();
                  final totalAmount = ds['totalAmount'];
                  final items = ds['items'] as List<dynamic>;
                  final address = ds['address'] ?? 'No Address Provided';
                  final Map<String, dynamic> data = ds.data() as Map<String, dynamic>;
                  final currentDeliveryStatus = data['deliveryStatus'] ?? 'Order Accepted';
                  final kitchenStatus = data['KitchenorderStatus'] ?? 'Pending';
                  final assignedDeliveryGuy = data['assignedDeliveryGuy'];

                  bool isPendingAssignment = (kitchenStatus == 'Out for Delivery' && assignedDeliveryGuy == null);
                  bool showDeliveryStatusDropdown = assignedDeliveryGuy != null;

                  print("Order $orderId => KitchenStatus: $kitchenStatus, DeliveryStatus: $currentDeliveryStatus, AssignedTo: ${assignedDeliveryGuy ?? 'None'}");

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
                        padding: EdgeInsets.all(10),
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
                            Text('Address: $address', style: TextStyle(fontWeight: FontWeight.w500)),
                            SizedBox(height: 8),
                            Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),

                            ...items.map((item) {
                              final itemName = item['Name'] ?? 'Unnamed';
                              final kitchenName = item['kitchenname'] ?? 'Unknown Kitchen';
                              final itemQuantity = item['quantity'] ?? 1;
                              print("  - $itemName x$itemQuantity from $kitchenName");

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Text('$itemName x$itemQuantity from $kitchenName'),
                              );
                            }).toList(),

                            Text('Kitchen Status: $kitchenStatus', style: TextStyle(fontWeight: FontWeight.bold)),

                            if (showDeliveryStatusDropdown)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Delivery Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  DropdownButton<String>(
                                    value: validCurrentDeliveryStatus,
                                    items: deliveryStatusOptions.map<DropdownMenuItem<String>>((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null && newValue != validCurrentDeliveryStatus) {
                                        print("Changing status of order $orderId to $newValue");
                                        _updateDeliveryStatus(orderId, newValue, data);
                                      }
                                    },
                                  ),
                                ],
                              ),

                            if (assignedDeliveryGuy != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Text("DEBUG: assignedDeliveryGuy is not null => $assignedDeliveryGuy"),
                                  SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                        icon: Icon(Icons.location_on, color: Colors.white,),
                                        label: Text("Show Location", style: TextStyle(color: Colors.white)),
                                        onPressed: () {
                                          print("Show location button pressed for order $orderId");
                                          _extractLatLngFromAddress(address);
                                          launchUrl(Uri.parse('https://www.google.com/maps?q=$clatitude,$clongitude'));
                                        },
                                      ),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                        icon: Icon(Icons.delivery_dining, color: Colors.white,),
                                        label: Text("Start Delivery", style: TextStyle(color: Colors.white)),
                                        onPressed: () {
                                          print("Start delivery button pressed for order $orderId");
                                          _updateDeliveryStatus(orderId, 'Out for Delivery', data);
                                          _extractLatLngFromAddress(address);
                                          _startDelivery(orderId);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            else
                              // Text("DEBUG: assignedDeliveryGuy is null for order $orderId"),

                            if (isPendingAssignment)
                              ElevatedButton(
                                onPressed: () async {
                                  print("Accept order button clicked for $orderId");
                                  await _assignOrderToDeliveryGuy(orderId);
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
                print("Navigating to Completed Orders");
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
