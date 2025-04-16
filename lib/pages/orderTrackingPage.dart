import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OrderTrackingPage extends StatefulWidget {
  final String orderId;

  const OrderTrackingPage({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  LatLng destination = LatLng(18.3363, 76.1489);
  LatLng deliveryBoyLocation = LatLng(10.3275, 76.35762);
  GoogleMapController? mapController;
  BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
  double remainingDistance = 0.0;

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  late CollectionReference orderTrackingCollection;

  @override
  void initState() {
    super.initState();
    fetchAndUpdateDestination(widget.orderId);
    orderTrackingCollection = firestore.collection('OrderTracking');
    addCustomMarker();

    // Start the location stream
    Geolocator.getPositionStream(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 10),
    ).listen((Position position){
      updateCurrentLocation(position);
    });

    // Start tracking the order ID
    startTracking(widget.orderId);
    updateDestination();  // Update destination with data from Firestore
  }

  void _extractLatLngFromAddress(String address) {
    final regex = RegExp(r'Lat:\s*(-?\d+\.\d+),\s*Lng:\s*(-?\d+\.\d+)');
    final match = regex.firstMatch(address);
    if (match != null) {
      double latitude = double.parse(match.group(1)!);
      double longitude = double.parse(match.group(2)!);

      // Update the destination LatLng with the extracted values
      setState(() {
        destination = LatLng(latitude, longitude);
      });

      print("Extracted latitude: $latitude, longitude: $longitude");
    } else {
      print("No coordinates found in address");
    }
  }

  Future<void> fetchAndUpdateDestination(String orderId) async {
    // Fetch the address from Firestore
    var orderDoc = await firestore.collection('Orders').doc(orderId).get();
    if (orderDoc.exists) {
      var address = orderDoc.data()?['address'] ?? '';
      print("Address from Firestore: $address");

      // Extract lat and lng from the address
      _extractLatLngFromAddress(address);
    } else {
      print("No order found with the given ID");
    }
  }


  // Function to set a custom marker icon
  void addCustomMarker() {
    ImageConfiguration configuration = ImageConfiguration(size: Size(0, 0), devicePixelRatio: 5,);
    BitmapDescriptor.fromAssetImage(configuration, "images/deliveryboy.png").then((icon) {
      setState(() {
        markerIcon = icon;
        print("✅ Custom marker icon set");
      });
    }).catchError((e) {
      print("❌ Error setting custom marker icon: $e");
    });
  }

  // Function to update current location
  double previousDistance = 0.0;

  void updateCurrentLocation(Position position) {
    LatLng newLocation = LatLng(position.latitude, position.longitude);
    double distance = Geolocator.distanceBetween(
      deliveryBoyLocation.latitude,
      deliveryBoyLocation.longitude,
      newLocation.latitude,
      newLocation.longitude,
    );

    // Update if the location change exceeds a certain threshold (e.g., 10 meters)
    if (distance > 10.0) {
      setState(() {
        deliveryBoyLocation = newLocation;
      });
      print("📍 Updated current location to: $deliveryBoyLocation");
    }
  }

  // Update delivery boy's location on the map and calculate remaining distance
  void updateDeliveryBoyLocation(Position position) {
    setState(() {
      deliveryBoyLocation = LatLng(position.latitude, position.longitude);
    });

    print("📍 Delivery Boy Location Updated: $deliveryBoyLocation");

    // Update the camera position to the new location
    mapController?.animateCamera(CameraUpdate.newLatLng(deliveryBoyLocation));

    // Calculate remaining distance to the destination
    calculateRemainingDistance();
  }

  void calculateRemainingDistance() {
    print("📍 Delivery Boy Location: $deliveryBoyLocation");
    print("📍 Destination Location: $destination");

    double distance = Geolocator.distanceBetween(
      deliveryBoyLocation.latitude,
      deliveryBoyLocation.longitude,
      destination.latitude,
      destination.longitude,
    );

    double distanceInKm = distance / 1000;
    setState(() {
      remainingDistance = distanceInKm;
    });

    print("Remaining Distance: $distanceInKm kilometers");
  }

  // Start tracking the order by periodically fetching tracking data
  void startTracking(String orderId) {
    print("Starting tracking for order ID: $orderId");
    Timer.periodic(Duration(seconds: 5), (timer) async {
      print("Checking tracking data for order ID: $orderId");

      var trackingData = await getOrderTracking(orderId);

      if (trackingData != null) {
        double latitude = trackingData['latitude'];
        double longitude = trackingData['longitude'];

        updateUIWithLocation(latitude, longitude);

        print('Updated location from Firestore: $latitude, $longitude');
      } else {
        print('❌ No tracking data available for order ID: $orderId');
      }
    });
  }

  // Fetch tracking data from Firestore
  Future<Map<String, dynamic>?> getOrderTracking(String orderId) async {
    try {
      var snapshot = await orderTrackingCollection.doc(orderId).get();
      if (snapshot.exists) {
        print("✅ Tracking data retrieved for order ID: $orderId");
        return snapshot.data() as Map<String, dynamic>;
      } else {
        print("❌ No document found for order ID: $orderId");
        return null;
      }
    } catch (e) {
      print("❌ Error retrieving order tracking information: $e");
      return null;
    }
  }

  // Update UI with new location data
  void updateUIWithLocation(double latitude, double longitude) {
    setState(() {
      deliveryBoyLocation = LatLng(latitude, longitude);

      print("📍 UI Updated with new location: $latitude, $longitude");

      // Update the camera position to the new location
      mapController?.animateCamera(
        CameraUpdate.newLatLng(deliveryBoyLocation),
      );

      // Recalculate remaining distance
      calculateRemainingDistance();
    });
  }

  // Fetch and update the destination address with latitude and longitude from Firestore
  Future<void> updateDestination() async {
    try {
      var orderSnapshot = await firestore.collection('Orders').doc(widget.orderId).get();
      if (orderSnapshot.exists) {
        String address = orderSnapshot['address']; // Example: "Virar, Virar West, India 401301 (Lat: 19.452074, Lng: 72.7726263)"

        // Regular expression to extract lat and long from the address string
        RegExp regExp = RegExp(r"\(Lat:\s*(-?\d+\.\d+),\s*Lng:\s*(-?\d+\.\d+)\)");
        Match? match = regExp.firstMatch(address);

        if (match != null) {
          double latitude = double.parse(match.group(1)!);
          double longitude = double.parse(match.group(2)!);

          setState(() {
            destination = LatLng(latitude, longitude);
            print("✅ Updated destination to: $destination");
          });

          // Recalculate the remaining distance
          calculateRemainingDistance();
        } else {
          print("❌ Failed to extract coordinates from address.");
        }
      } else {
        print("❌ No order found with ID: ${widget.orderId}");
      }
    } catch (e) {
      print("❌ Error updating destination: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Order Tracking"),
      ),
      body: Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              onMapCreated: (controller) {
                mapController = controller;
                print("✅ Google Map controller created");
              },
              initialCameraPosition: CameraPosition(
                target: deliveryBoyLocation,
                zoom: 14.0,
              ),
              markers: {
                Marker(
                  markerId: MarkerId("deliveryBoy"),
                  position: deliveryBoyLocation,
                  icon: markerIcon,
                  infoWindow: InfoWindow(title: "Your Location", snippet: 'Lat: ${destination.latitude}, Lng: ${destination.longitude}'),
                ),
                Marker(
                  markerId: MarkerId("destination"),
                  position: destination,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                  infoWindow: InfoWindow(title: "Customer", snippet: 'Lat: ${destination.latitude}, Lng: ${destination.longitude}'),
                ),
              },
            ),
            Positioned(
              top: 16.01,
              left: 8,
              right: 6,
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(8.8),
                  decoration: BoxDecoration(
                    color: Colors.yellow,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    "Remaining Distance: ${remainingDistance.toStringAsFixed(2)} kilometers",
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
              ),
            )
          ]
      ),
    );
  }
}