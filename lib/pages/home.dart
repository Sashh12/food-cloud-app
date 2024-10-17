import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodapp/pages/KitchenFood.dart';
import 'package:foodapp/pages/details2.dart';
import 'package:foodapp/service/database.dart';
import '../widget/widget_support.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? name;
  final FirebaseAuth auth = FirebaseAuth.instance;
  bool icecream = false, pizza = false, burger = false, fries = false;
  List<Map<String, dynamic>> products = [];

  Stream? foodItemStream;

  ontheload()async{
    foodItemStream = await DatabaseMethods().getFoodItem("Burger");
    allItems();
    setState(() {
    });
  }

  Future<void> fetchUserData() async {
    try {
      User? user = auth.currentUser;
      if (user != null) {
        print('Fetching data for user ID: ${user.uid}');
        DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (snapshot.exists) {
          Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

          print('Fetched data: $data');

          if (data != null) {
            setState(() {
              name = data['Name']; // Ensure this matches your Firestore structure
            });
          }
        } else {
          print('No document exists for user ID: ${user.uid}');
        }
      } else {
        print('No user is currently logged in.');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    ontheload();
    onLoad();
    fetchUserData();
  }

  Future<void> onLoad() async {
    setState(() {
      // Optional: Indicate loading state if needed
    });

    try {
      // Fetch your data here
      var data = await DatabaseMethods().fetchAllProducts();

      // Update the state with the fetched data
      setState(() {
        // Assign the fetched data to a variable
        products = data; // Assuming you have a `products` variable to hold the data
      });
    } catch (e) {
      print("Error loading data: $e");
      // Handle errors as needed
    }
  }

  // @override
  // void initState() {
  //   ontheload();
  //    TODO: implement initState
  //   super.initState();
  // }

  Widget allItems2(){
    return StreamBuilder( stream: foodItemStream, builder: (context, AsyncSnapshot snapshot){
      return snapshot.hasData? ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: snapshot.data.docs.length,
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context,index){
            DocumentSnapshot ds = snapshot.data.docs[index];
            return GestureDetector(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>Detail(detail: ds["Detail"],name: ds["Name"], image: ds["Image"], price: ds["Price"],
                  kitchenname: ds["Kitchenname"],
                )));
              },
              child: Container(
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
                          child: Image.network(ds["Image"], height: 180, width: 180,
                            fit: BoxFit.cover,),
                        ),
                        Text(ds["Name"], style: AppWidget.FoodNameText(),),
                        SizedBox(height: 5.0,),
                        Text("Delicious and Juicy", style: AppWidget.LightTextFieldStyle(),),
                        SizedBox(height: 5.0,),
                        Text("\₹"+ds["Price"], style: AppWidget.SemiBoldFieldStyle2(),),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }): Center(child: CircularProgressIndicator());
    });
  }

  Widget allItems() {
    if (products.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: products.length,
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) {
        var product = products[index]['Product'];
        var category = products[index]['Category'];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Detail(
                  detail: product["Detail"],
                  name: product["Name"],
                  image: product["Image"],
                  price: product["Price"],
                  kitchenname: product["kitchenname"],
                ),
              ),
            );
          },
          child: Container(
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
                        product["Image"],
                        height: 180,
                        width: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Text(
                      product["Name"],
                      style: AppWidget.FoodNameText(),
                    ),
                    SizedBox(height: 5.0),
                    Text(
                      "Delicious and Juicy",
                      style: AppWidget.LightTextFieldStyle(),
                    ),
                    SizedBox(height: 5.0),
                    Text(
                      "₹" + product["Price"],
                      style: AppWidget.SemiBoldFieldStyle2(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget allKitchensVertically() {
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
              String imageUrl = ds["ImageUrl"] ?? "https://via.placeholder.com/90"; // Default placeholder image

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
                          SizedBox(height: 20,),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Image.network(imageUrl, height: 90, width: 90, fit: BoxFit.cover),
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(top: 50.0, left: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Hello, ${name?.split(' ').first ?? ''}", style: AppWidget.SemiBoldFieldStyle()),
                  Container(
                    margin: EdgeInsets.only(right: 20.0),
                    padding: EdgeInsets.all(3),
                    decoration: BoxDecoration(color: Colors.black,
                      borderRadius: BorderRadius.circular(8),),
                    child: Icon(Icons.shopping_cart_outlined, color: Colors.white,),
                  ),
                ],
              ),
              SizedBox(height: 30.0),
              Text("Delicious Food",
                style: AppWidget.HeaderLineTextFieldStyle(),
              ),
              Text(
                "Discover and Get Great Food",
                style: AppWidget.LightTextFieldStyle(),
              ),
              SizedBox(height: 20.0),
              Container(
                margin: EdgeInsets.only(right: 20.0),
                  child: showItem()),
              SizedBox(height: 20.0),

              Container(
                  height: 330,
                  child: allItems2()),
              SizedBox(height: 30.0),
              allKitchensVertically(),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0), // Optional padding for aesthetics
                    child: Text(
                      "All Items",
                      style: TextStyle(
                        fontSize: 24, // Font size
                        fontWeight: FontWeight.bold, // Make it bold
                      ),
                    ),
                  ),
                  Container(
                    height: 330,
                    child: allItems(), // Call your allItems widget
                  ),
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget showItem() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () async{
            burger = true;
            icecream = false;
            pizza = false;
            fries = false;
            foodItemStream = await DatabaseMethods().getFoodItem("Burger");
            setState(() {});
          },
          child: Material(
            elevation: 5.0,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: burger ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.all(8),
              child: Image.asset(
                "images/burger.png",
                height: 40,
                width: 40,
                fit: BoxFit.cover,
                color: burger ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () async{
            burger = false;
            icecream = false;
            pizza = true;
            fries = false;
            foodItemStream = await DatabaseMethods().getFoodItem("Pizza");
            setState(() {});
          },
          child: Material(
            elevation: 5.0,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: pizza ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.all(8),
              child: Image.asset(
                "images/pizza.png",
                height: 40,
                width: 40,
                fit: BoxFit.cover,
                color: pizza ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: ()async {
            burger = false;
            icecream = true;
            pizza = false;
            fries = false;
            foodItemStream = await DatabaseMethods().getFoodItem("Ice-cream");
            setState(() {});
          },
          child: Material(
            elevation: 5.0,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: icecream ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.all(8),
              child: Image.asset(
                "images/ice-cream.png",
                height: 40,
                width: 40,
                fit: BoxFit.cover,
                color: icecream ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () async{
            icecream = false;
            pizza = false;
            burger = false;
            fries = true;
            foodItemStream = await DatabaseMethods().getFoodItem("Fries");
            setState(() {});
          },
          child: Material(
            elevation: 5.0,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: fries ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.all(8),
              child: Image.asset("images/fried-potatoes.png", height: 40, width: 40,
                fit: BoxFit.cover, color: fries ? Colors.white : Colors.black,),
            ),
          ),
        ),
      ],
    );
  }
}
