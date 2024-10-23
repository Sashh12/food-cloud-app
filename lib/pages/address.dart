import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddAddressScreen extends StatefulWidget {
  @override
  _AddAddressScreenState createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final TextEditingController addressController = TextEditingController();
  List<String> addressList = [];

  // Function to save the address to Firestore
  Future<void> saveAddress() async {
    User? user = FirebaseAuth.instance.currentUser;
    String? userId = user?.uid;

    if (userId != null) {
      // Fetch the current user's document
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      // Ensure "addresses" field exists
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?; // Cast to Map
      if (userData == null || !userData.containsKey('addresses')) {
        // If userData is null or does not contain 'addresses', initialize it
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'addresses': [],
        }, SetOptions(merge: true)); // Use merge to avoid overwriting existing data
      }

      // Add the last entered address to Firestore (assuming it's the new one)
      if (addressController.text.isNotEmpty) {
        String newAddress = addressController.text; // Get the address from the controller
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'addresses': FieldValue.arrayUnion([newAddress]),
        });
        addressList.add(newAddress); // Add to the local list to show in UI
        addressController.clear(); // Clear the input field
      }

      // Navigate back to the previous screen
      Navigator.pop(context);
    } else {
      // If no user is signed in, show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not signed in.')),
      );
    }
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
            SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // Add the entered address to the list
                  if (addressController.text.isNotEmpty) {
                    addressList.add(addressController.text);
                    addressController.clear(); // Clear the input after adding
                  }
                });
              },
              child: Text('Add Address'),
            ),
            SizedBox(height: 20.0),
            // Display the list of added addresses
            Expanded(
              child: ListView.builder(
                itemCount: addressList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(addressList[index]),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          addressList.removeAt(index); // Remove address from list
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: saveAddress, // Save addresses to Firestore
              child: Text('Save Addresses'),
            ),
          ],
        ),
      ),
    );
  }
}
