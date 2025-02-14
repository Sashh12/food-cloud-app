import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class DatabaseMethods{
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future addUserDetail(String id, Map<String, dynamic>  userInfoMap)async{
    return await FirebaseFirestore.instance.collection("users").doc(id).set(userInfoMap);
  }
  
  UpdateUserwallet(String id, String amount)async{
    return await FirebaseFirestore.instance.collection("users").doc(id).update({"Wallet": amount});
  }

  Future addFoodItem(String name, Map<String, dynamic>  userInfoMap)async{
    return await FirebaseFirestore.instance.collection(name).add(userInfoMap);
  }

  Future placeOrder(String userId, int totalAmount, List<Map<String, dynamic>> items) async {
    String orderId = FirebaseFirestore.instance.collection("orders").doc().id;
    await FirebaseFirestore.instance.collection("orders").doc(orderId).set({
      "userId": userId,
      "totalAmount": totalAmount,
      "orderDate": Timestamp.now(),
      "items": items,
    });
  }

  Future<Stream<QuerySnapshot>> getFoodItem(String name)async{
    return await FirebaseFirestore.instance.collection(name).snapshots();
  }

  Future addFoodtoCart(String id, Map<String, dynamic> userInfoMap) async {
    // Get a reference to the user's cart collection
    var cartRef = FirebaseFirestore.instance.collection("users").doc(id).collection("Cart");

    // Check if the item already exists in the cart
    var querySnapshot = await cartRef.where('Name', isEqualTo: userInfoMap['Name']).get();

    if (querySnapshot.docs.isNotEmpty) {
      // Item exists, so update the quantity
      var doc = querySnapshot.docs.first; // Get the first document that matches the item
      int newQuantity = int.parse(doc['Quantity']) + int.parse(userInfoMap['Quantity']);

      // Update the existing item with the new quantity
      await doc.reference.update({'Quantity': newQuantity.toString()});
    } else {
      // Item does not exist, so add it as a new item
      await cartRef.add(userInfoMap);
    }
  }

  Future<Stream<QuerySnapshot>> getFoodCart(String id)async{
    return await FirebaseFirestore.instance.collection("users").doc(id).collection("Cart").snapshots();
  }

  Future addCloudKitchenDetail(String id, Map<String, dynamic> userInfoMap) async {
    return await FirebaseFirestore.instance.collection("kitchens").doc(id).set(userInfoMap);
  }

  // Future<List<Map<String, dynamic>>> fetchAllItemsFromAllKitchens() async {
  //   List<Map<String, dynamic>> allItems = [];
  //
  //   try {
  //     print("Starting to fetch items from all kitchens...");
  //
  //     QuerySnapshot kitchensSnapshot = await FirebaseFirestore.instance.collection('fooditem').get();
  //     print("Fetched ${kitchensSnapshot.docs.length} kitchens.");
  //
  //     // Debugging line to print the fetched kitchens
  //     print("Kitchens data: ${kitchensSnapshot.docs.map((doc) => doc.data()).toList()}");
  //
  //     if (kitchensSnapshot.docs.isEmpty) {
  //       print("No kitchens found in the fooditem collection.");
  //       return allItems;
  //     }
  //
  //     for (var kitchenDoc in kitchensSnapshot.docs) {
  //       String kitchenName = kitchenDoc.id;
  //       print("Fetching items for kitchen: $kitchenName");
  //
  //       QuerySnapshot categoriesSnapshot = await kitchenDoc.reference.collection('categories').get();
  //       print("Fetched ${categoriesSnapshot.docs.length} categories for kitchen: $kitchenName");
  //       print("Categories data: ${categoriesSnapshot.docs.map((doc) => doc.data()).toList()}");
  //
  //       if (categoriesSnapshot.docs.isEmpty) {
  //         print("No categories found for kitchen: $kitchenName");
  //         continue;
  //       }
  //
  //       for (var categoryDoc in categoriesSnapshot.docs) {
  //         print("Fetching items for category: ${categoryDoc.id}");
  //
  //         QuerySnapshot itemsSnapshot = await categoryDoc.reference.collection('Items').get();
  //         print("Fetched ${itemsSnapshot.docs.length} items for category: ${categoryDoc.id}");
  //         print("Items data: ${itemsSnapshot.docs.map((doc) => doc.data()).toList()}");
  //
  //         if (itemsSnapshot.docs.isEmpty) {
  //           print("No items found for category: ${categoryDoc.id}");
  //           continue;
  //         }
  //
  //         for (var itemDoc in itemsSnapshot.docs) {
  //           Map<String, dynamic> itemData = itemDoc.data() as Map<String, dynamic>;
  //           itemData['Kitchenname'] = kitchenName;
  //           allItems.add(itemData);
  //           print("Added item: ${itemData['Name']} from kitchen '$kitchenName' to the list.");
  //         }
  //       }
  //     }
  //
  //     print("Total items fetched from all kitchens: ${allItems.length}");
  //     return allItems;
  //
  //   } catch (e) {
  //     print("Error fetching items: $e");
  //     return [];
  //   }
  // }




} //class ending




