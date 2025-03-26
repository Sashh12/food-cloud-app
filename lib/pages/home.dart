import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodapp/main.dart';
import 'package:foodapp/pages/filterproducts.dart';
import 'package:foodapp/pages/rulechatbot.dart';
import 'package:foodapp/pages/KitchenFood.dart';
import 'package:foodapp/pages/details2.dart';
import 'package:foodapp/service/voicesearch.dart';
import '../widget/widget_support.dart';
import 'package:permission_handler/permission_handler.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? name;
  final FirebaseAuth auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> products = [];
  final SpeechService speechService = SpeechService();
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredProducts = [];
  bool isSearching = false;


  @override
  void initState() {
    super.initState();
    onLoad();
    fetchUserData();
    speechService.initSpeech();
    // requestPermissions();
  }

  // Future<void> requestPermissions() async {
  //   var status = await Permission.microphone.request();
  //   if (status.isGranted) {
  //     print("✅ Microphone permission granted.");
  //   } else {
  //     print("❌ Microphone permission denied.");
  //   }
  // }

  // Fetch current user data (name) from Firestore
  Future<void> fetchUserData() async {
    try {
      User? user = auth.currentUser;
      if (user != null) {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (snapshot.exists) {
          Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
          if (data != null && mounted) {  // Check if mounted before setState
            setState(() {
              name = data['Name'];
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> onLoad() async {
    try {
      List<Map<String, dynamic>> allItems = [];
      bool dataFound = false; // Flag to track if any data is found

      QuerySnapshot kitchenSnapshot = await FirebaseFirestore.instance.collection('kitchens').get();

      if (kitchenSnapshot.docs.isEmpty) {
        print("No kitchens found.");
      } else {
        for (var kitchenDoc in kitchenSnapshot.docs) {
          String kitchenName = kitchenDoc["kitchenname"];
          if (kitchenName != null && kitchenName.isNotEmpty) {
            QuerySnapshot categorySnapshot = await FirebaseFirestore.instance
                .collection('fooditem')
                .doc(kitchenName)
                .collection('categories')
                .get();

            for (var categoryDoc in categorySnapshot.docs) {
              String categoryName = categoryDoc.id;
              QuerySnapshot itemSnapshot = await FirebaseFirestore.instance
                  .collection('fooditem')
                  .doc(kitchenName)
                  .collection('categories')
                  .doc(categoryName)
                  .collection('Items')
                  .get();

              for (var itemDoc in itemSnapshot.docs) {
                Map<String, dynamic> itemData = itemDoc.data() as Map<String, dynamic>;
                allItems.add(itemData);
                dataFound = true;
              }
            }
          }
        }
      }

      if (!dataFound) {
        print("No items found in the entire database.");
      }

      if (mounted) { // Check before calling setState
        setState(() {
          products = allItems;
        });
      }
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  // Display all items fetched from Firestore
  Widget allItems() {
    return products.isEmpty ? Center(child: CircularProgressIndicator()): ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: products.length,
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) {
        Map<String, dynamic> itemData = products[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Detail(
                  detail: itemData["Detail"] ?? "",
                  name: itemData["Name"] ?? "No Name",
                  image: itemData["Image"] ?? "https://via.placeholder.com/180",
                  price: itemData["Price"] ?? "0",
                  kitchenname: itemData["kitchenname"] ?? "",
                  ingredients: itemData["Ingredients"] ?? "",
                  optionalIngredients: itemData["optionalIngredients"] ?? "",
                  spiceLevels: itemData["spiceLevels"] ?? "",
                  FoodCategory: itemData["FoodCategory"] ?? "",

                ),
              ),
            );
          },
          child: buildProductCardFromMap(itemData),
        );
      },
    );
  }

  // Build product card from map of item data
  Widget buildProductCardFromMap(Map<String, dynamic> product) {
    String imageUrl = product["Image"] ?? "https://via.placeholder.com/180";
    String name = product["Name"] ?? "No Name";
    String price = product["Price"] ?? "0";

    return Container(
      margin: EdgeInsets.all(4),
      child: Material(
        elevation: 5.0,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  imageUrl,
                  height: 180,
                  width: 180,
                  fit: BoxFit.cover,
                ),
              ),
              Text(name, style: AppWidget.FoodNameText()),
              SizedBox(height: 5.0),
              Text("Delicious and Juicy", style: AppWidget.LightTextFieldStyle()),
              SizedBox(height: 5.0),
              Text("₹$price", style: AppWidget.SemiBoldFieldStyle2()),
            ],
          ),
        ),
      ),
    );
  }

  // Build a list of kitchens
  Widget buildKitchens() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('kitchens').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: snapshot.data!.docs.length,
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            itemBuilder: (context, index) {
              DocumentSnapshot ds = snapshot.data!.docs[index];

              // Safely access kitchen name and image URL with default values
              String kitchenName = ds["kitchenname"] ?? "No Name";
              String? imageUrl = ds["ImageUrl"]; // Nullable image URL

              return GestureDetector(
                onTap: () {
                  // Ensure kitchenName is not null before navigating
                  if (kitchenName.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FoodItemsPage(kitchenname: kitchenName),
                      ),
                    );
                  }
                },
                child: Container(
                  margin: EdgeInsets.only(right: 20.0, bottom: 20.0),
                  height: 100.0,
                  child: Material(
                    elevation: 5.0,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? Image.network(imageUrl, height: 90, width: 90, fit: BoxFit.cover)
                                : Container(
                              height: 90,
                              width: 90,
                              color: Colors.grey.shade300,
                              child: Icon(Icons.person, size: 40, color: Colors.grey),
                            ),
                          ),
                          SizedBox(width: 10.0),
                          Text(
                            kitchenName,
                            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  void filterSearch(String query) {
    if (products.isEmpty) return;

    List<Map<String, dynamic>> filtered = SearchService.filterProducts(products, query);

    if (query.isNotEmpty) {
      // Navigate to the FilteredProductsPage with the filtered products
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FilteredProductsPage(filteredProducts: filtered),
        ),
      ).then((_) {
        // Clear the search field after returning from the search page
        searchController.clear();
        setState(() {}); // Trigger UI update
      });
    }
  }

  void showListeningDialog(bool isListening) {
    BuildContext? context = navKey.currentContext;
    if (context == null) return; // Ensure context is available

    // Close any existing dialog first
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              isListening
                  ? CircularProgressIndicator()
                  : Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 20),
              Text(isListening ? "Listening..." : "Done!", style: TextStyle(fontSize: 18)),
            ],
          ),
        );
      },
    );

    // If listening is done, close the dialog after 20 seconds
    if (!isListening) {
      Future.delayed(Duration(seconds: 5), () {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      });
    }
  }



  Widget buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(right: 15.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: "Search food...",
            prefixIcon: Icon(Icons.search),
            suffixIcon: IconButton(
              icon: Icon(Icons.mic),
              onPressed: () async {
                var status = await Permission.microphone.request();
                if (status.isGranted) {
                  print("✅ Microphone permission granted.");

                  speechService.startListening(
                        (voiceInput) {
                      setState(() {
                        searchController.text = voiceInput;
                      });
                      filterSearch(voiceInput);
                    },
                    context,
                    showListeningDialog, // Pass the function
                  );
                } else {
                  print("❌ Microphone permission denied.");
                }
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          onSubmitted: (query) {
            filterSearch(query); // Trigger search only when Enter is pressed
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              margin: EdgeInsets.only(top: 50.0, left: 18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Hello, ${name?.split(' ').first ?? ''}",
                          style: AppWidget.SemiBoldFieldStyle()),
                      Container(
                        margin: EdgeInsets.only(right: 20.0),
                        padding: EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.shopping_cart_outlined, color: Colors.white),
                      ),
                    ],
                  ),
                  buildSearchBar(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Kitchens",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(height: 250, child: buildKitchens()),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "All Items",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(height: 330, child: allItems()),
                ],
              ),
            ),
          ),

          // Chatbot Floating Button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatScreen()),
                );
              },
              backgroundColor: Colors.blue,
              child: Icon(Icons.chat, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
