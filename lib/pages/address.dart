import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AddAddressScreen extends StatefulWidget {
  @override
  _AddAddressScreenState createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final TextEditingController addressController = TextEditingController();
  LatLng? selectedLocation;

  Future<void> saveAddress() async {
    User? user = FirebaseAuth.instance.currentUser;
    String? userId = user?.uid;

    if (userId != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      if (userData == null || !userData.containsKey('addresses')) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'addresses': [],
        }, SetOptions(merge: true));
      }

      String newAddress;
      if (addressController.text.isNotEmpty) {
        newAddress = addressController.text;
      } else if (selectedLocation != null) {
        newAddress = await _getAddressFromLatLng(selectedLocation!);
      } else {
        newAddress = 'No address available';
      }

      if (selectedLocation != null) {
        Map<String, dynamic> addressMap = {
          'address': newAddress,
          'latitude': selectedLocation!.latitude,
          'longitude': selectedLocation!.longitude,
        };

        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'addresses': FieldValue.arrayUnion([addressMap]),
        });

        setState(() {
          addressController.clear();
          selectedLocation = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Address saved successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a location before saving.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not signed in.')),
      );
    }
  }

  Future<String> _getAddressFromLatLng(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      Placemark placemark = placemarks.first;
      return '${placemark.locality}, ${placemark.subLocality}, ${placemark.country} ${placemark.postalCode}';
    } catch (e) {
      print('Error getting address: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to fetch address.')));
      return 'Unknown address';
    }
  }

  Future<void> _pickLocation() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return LocationPickerAlert(
          onLocationSelected: (LatLng userLocation) async {
            setState(() {
              selectedLocation = userLocation;
            });
            // Autofill the address text field with the selected location's address
            String autofilledAddress = await _getAddressFromLatLng(userLocation);
            addressController.text = autofilledAddress;
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Address'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: addressController,
              decoration: InputDecoration(labelText: 'Enter Address'),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _pickLocation,
              icon: Icon(Icons.location_on),
              label: const Text('Select Location from Map'),
            ),
            SizedBox(height: 20.0),
            if (selectedLocation != null)
              Text('Selected Location: Lat: ${selectedLocation!.latitude}, Lng: ${selectedLocation!.longitude}'),
            SizedBox(height: 20.0),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading addresses.'));
                  }
                  if (!snapshot.hasData || snapshot.data?.data() == null) {
                    return Center(child: Text('No addresses found.'));
                  }
                  List<dynamic> addresses = (snapshot.data!.data() as Map<String, dynamic>)['addresses'] ?? [];
                  return ListView.builder(
                    itemCount: addresses.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> address = addresses[index];
                      return ListTile(
                        title: Text(address['address']),
                        subtitle: Text('Lat: ${address['latitude']}, Lng: ${address['longitude']}'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser?.uid)
                                .update({
                              'addresses': FieldValue.arrayRemove([address]),
                            });
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: saveAddress,
              child: Text('Save Address'),
            ),
          ],
        ),
      ),
    );
  }
}

class LocationPickerAlert extends StatefulWidget {
  final Function(LatLng)? onLocationSelected;

  const LocationPickerAlert({Key? key, this.onLocationSelected}) : super(key: key);

  @override
  LocationPickerAlertState createState() => LocationPickerAlertState();
}

class LocationPickerAlertState extends State<LocationPickerAlert> {
  GoogleMapController? mapController;
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  void _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permission is required.')),
      );
    } else {
      _getCurrentLocation();
    }
  }

  void _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        mapController?.animateCamera(CameraUpdate.newLatLng(_selectedLocation!));
      });
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Expanded(
              child: GoogleMap(
                mapType: MapType.terrain,
                onMapCreated: (controller) {
                  mapController = controller;
                },
                onTap: (latLng) {
                  setState(() {
                    _selectedLocation = latLng;
                  });
                },
                markers: _selectedLocation != null
                    ? {
                  Marker(
                    markerId: const MarkerId('selectedLocation'),
                    position: _selectedLocation!,
                  ),
                }
                    : {},
                initialCameraPosition: const CameraPosition(
                  target: LatLng(0, 0),
                  zoom: 10,
                ),
                myLocationEnabled: true,
              ),
            ),
            FloatingActionButton(
              onPressed: () {
                if (_selectedLocation != null) {
                  Navigator.pop(context);
                  widget.onLocationSelected?.call(_selectedLocation!);
                }
              },
              child: const Icon(Icons.check),
            ),
          ],
        ),
      ),
    );
  }
}
