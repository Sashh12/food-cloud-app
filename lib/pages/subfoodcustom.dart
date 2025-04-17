import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodapp/pages/healthyitems.dart';
import 'package:intl/intl.dart';

class SubCustomizationDialog extends StatefulWidget {
  final Map<String, dynamic> foodItem;
  final String? id;
  final int a;
  final int total;

  SubCustomizationDialog({
    required this.foodItem,
    required this.id,
    required this.a,
    required this.total,
  });

  @override
  _SubCustomizationDialogState createState() => _SubCustomizationDialogState();
}

class _SubCustomizationDialogState extends State<SubCustomizationDialog> {
  List<String> selectedIngredients = [];
  String selectedSpiceLevel = "Mild";
  String customInstructions = "";
  String? id;

  @override
  void initState() {
    super.initState();
    getUserId();
  }

  getUserId() {
    id = FirebaseAuth.instance.currentUser?.uid;
    setState(() {});
  }

  DateTime getDateForDay(String dayOfWeek) {
    DateTime now = DateTime.now();
    int currentWeekday = now.weekday; // Monday = 1, ..., Sunday = 7

    Map<String, int> dayMapping = {
      'Sunday': 7,
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
    };

    int dayTarget = dayMapping[dayOfWeek]!;
    int difference = dayTarget - currentWeekday;

    // Get the date for the selected day
    DateTime selectedDate = now.add(Duration(days: difference));
    return selectedDate;
  }

  Future<void> showSubscribeDialog(Map<String, dynamic> foodItem, String customization) async {
    bool isSaving = false;
    BuildContext outerContext = context;
    List<String> daysOfWeek = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];

    String selectedDay = '';
    DateTime selectedDate = DateTime.now();
    TimeOfDay? selectedLunchTime;
    TimeOfDay? selectedDinnerTime;

    DateTime now = DateTime.now();

    showDialog(
      context: outerContext,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text('Select a Day for Subscription'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    "Subscription Week: ${DateFormat('dd/MM/yy').format(DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)))} - "
                        "${DateFormat('dd/MM/yy').format(DateTime.now().add(Duration(days: 7 - DateTime.now().weekday)))}"
                ),
                SizedBox(height: 10),
                DropdownButton<String>(
                  value: selectedDay.isEmpty ? null : selectedDay,
                  hint: Text("Choose a Day"),
                  onChanged: (String? newValue) {
                    print("Dropdown value changed to: $newValue");
                    setState(() {
                      selectedDay = newValue!;
                      selectedDate = getDateForDay(newValue);
                      print("Selected day: $selectedDay, Selected date: $selectedDate");
                    });
                  },
                  items: daysOfWeek.map((String day) {
                    DateTime dayDate = getDateForDay(day);
                    bool isDisabled = dayDate.isBefore(now);

                    return DropdownMenuItem<String>(
                      value: day,
                      enabled: !isDisabled,
                      child: Text(
                        "$day - ${DateFormat('dd/MM/yy').format(dayDate)}",
                        style: isDisabled ? TextStyle(color: Colors.grey) : null,
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 10),
                // Lunch time picker
                Row(
                  children: [
                    Text('Lunch Time: '),
                    TextButton(
                      onPressed: () async {
                        TimeOfDay initialTime = selectedDay == DateFormat('EEEE').format(now)
                            ? TimeOfDay(hour: now.hour, minute: now.minute)
                            : TimeOfDay(hour: 11, minute: 0); // Start from 11 AM

                        print("Initial lunch time: $initialTime");
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: initialTime,
                        );

                        if (pickedTime != null) {
                          final pickedInMinutes = pickedTime.hour * 60 + pickedTime.minute;
                          final minLunchTime = 11 * 60;  // 11:00 AM
                          final maxLunchTime = 16 * 60;  // 4:00 PM

                          print("Picked lunch time in minutes: $pickedInMinutes");

                          if (pickedInMinutes < minLunchTime || pickedInMinutes > maxLunchTime) {
                            print("Invalid lunch time selected.");
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text("Invalid Time"),
                                content: Text("Lunch time must be between 11 AM and 4 PM."),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text("OK"),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            setState(() {
                              selectedDinnerTime = null; // Deselect dinner if lunch is selected
                              selectedLunchTime = pickedTime;
                              print("Lunch time selected: ${selectedLunchTime!.format(context)}");
                            });
                          }
                        }
                      },
                      child: Text(selectedLunchTime == null
                          ? "Select Time"
                          : selectedLunchTime!.format(context)),
                    ),
                  ],
                ),
                // Dinner time picker
                Row(
                  children: [
                    Text('Dinner Time: '),
                    TextButton(
                      onPressed: () async {
                        TimeOfDay initialTime = selectedDay == DateFormat('EEEE').format(now)
                            ? TimeOfDay(hour: now.hour, minute: now.minute)
                            : TimeOfDay(hour: 19, minute: 0); // Start from 7 PM

                        print("Initial dinner time: $initialTime");
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: initialTime,
                        );

                        if (pickedTime != null) {
                          final pickedInMinutes = pickedTime.hour * 60 + pickedTime.minute;
                          final minDinnerTime = 19 * 60;  // 7:00 PM
                          final maxDinnerTime = 23 * 60;  // 11:00 PM

                          print("Picked dinner time in minutes: $pickedInMinutes");

                          if (pickedInMinutes < minDinnerTime || pickedInMinutes > maxDinnerTime) {
                            print("Invalid dinner time selected.");
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text("Invalid Time"),
                                content: Text("Dinner time must be between 7 PM and 11 PM."),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text("OK"),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            setState(() {
                              selectedLunchTime = null; // Deselect lunch if dinner is selected
                              selectedDinnerTime = pickedTime;
                              print("Dinner time selected: ${selectedDinnerTime!.format(context)}");
                            });
                          }
                        }
                      },
                      child: Text(selectedDinnerTime == null
                          ? "Select Time"
                          : selectedDinnerTime!.format(context)),
                    ),
                  ],
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  print("Subscribe button clicked");

                  if (selectedDay.isNotEmpty && (selectedLunchTime != null || selectedDinnerTime != null)) {
                    print("Proceeding to save subscription...");

                    Navigator.of(context).pop(); // Close the dialog first

                    bool isSaved = await saveSubscription(
                      foodItem,
                      customization,
                      selectedDay,
                      selectedDate,
                      selectedLunchTime,
                      selectedDinnerTime,
                    );

                    // Feedback via print instead of SnackBar
                    if (isSaved) {
                      print("✅ Subscription saved for $selectedDay");
                    } else {
                      print("❌ Failed to save subscription");
                    }
                  } else {
                    print("⚠️ Please select a day and a time");
                  }
                },
                child: Text('Cancel'),
              ),


              TextButton(
                onPressed: () async {
                  print("Subscribe button clicked");

                  if (selectedDay.isNotEmpty && (selectedLunchTime != null || selectedDinnerTime != null)) {
                    print("Proceeding to save subscription...");

                    Navigator.of(context).pop(); // Close the dialog first

                    bool isSaved = await saveSubscription(
                      foodItem,
                      customization,
                      selectedDay,
                      selectedDate,
                      selectedLunchTime,
                      selectedDinnerTime,
                    );

                    // Now show snackbar in outerContext (not dialog context)
                    ScaffoldMessenger.of(outerContext).showSnackBar(
                      SnackBar(
                        content: Text(isSaved
                            ? "Subscription saved for $selectedDay"
                            : "Failed to save subscription"),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please select a day and a time")),
                    );
                  }
                },
                child: Text('Subscribe'),
              )

            ],
          );
        });
      },
    );
  }

  Future<bool> saveSubscription(
      Map<String, dynamic> foodItem,
      String customization,
      String dayOfWeek,
      DateTime date,
      TimeOfDay? lunchTime,
      TimeOfDay? dinnerTime,
      ) async {
    print("Entered saveSubscription function");

    // Log id to confirm it’s not null
    print("id value before saving: $id");

    if (id != null) {
      print("id is valid, proceeding to save subscription");

      // Custom function to format TimeOfDay as HH:mm
      String formatTime(TimeOfDay time) {
        final now = DateTime.now();
        final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        return DateFormat('HH:mm').format(dt);
      }

      // Create subscription data to be saved
      Map<String, dynamic> subscriptionData = {
        "productName": foodItem["name"],
        "price": foodItem["price"],
        "customization": customization,
        "day": dayOfWeek,
        "date": DateFormat('dd/MM/yy').format(date),
        "lunchTime": lunchTime != null ? formatTime(lunchTime) : "Not Set",
        "dinnerTime": dinnerTime != null ? formatTime(dinnerTime) : "Not Set",
        "kitchenName": foodItem["kitchenName"],
        "FoodCategory": foodItem["FoodCategory"],
      };

      print("Subscription data being saved: $subscriptionData");

      try {
        print("Attempting to save subscription to Firestore...");
        await FirebaseFirestore.instance
            .collection('subscribe')
            .doc(id)
            .collection('days')
            .doc(dayOfWeek)
            .set(subscriptionData);

        print("✅ Subscription saved successfully");
        return true;
      } catch (e) {
        print(" Firebase error while saving subscription: $e");
        return false;
      }
    } else {
      print("⚠️ Error: id is null");
      return false;
    }
  }

  Future<void> junkCheck(BuildContext context, String id, Map<String, dynamic> foodItem, VoidCallback onCheckout) async {
    print("🚀 Checkout button clicked! Checking for junk orders...");

    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final pastWeek = now.subtract(Duration(days: 7));

    final parentContext = context;

    try {
      // 🟢 Fetch Order History for the past 7 days
      QuerySnapshot orderSnapshot = await firestore
          .collection("order_history")
          .where("userId", isEqualTo: id)
          .where("orderDate", isGreaterThanOrEqualTo: Timestamp.fromDate(pastWeek))
          .get();

      print("📦 Total orders in past 7 days: ${orderSnapshot.docs.length}");

      // 🟢 Count junk orders
      int junkOrderCount = orderSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?; // Explicitly cast
        if (data == null || !data.containsKey("items") || data["items"] == null) return false;

        List<dynamic> items = data["items"]; // Ensure it's a List
        return items.any((item) {
          if (item is Map<String, dynamic> && item.containsKey("FoodCategory")) {
            return item["FoodCategory"] == "Junk";
          }
          return false;
        });
      }).length;

      print("🚨 Junk orders found: $junkOrderCount");

      // 🟢 Check if the current food item is Junk
      bool isJunkItem = foodItem.containsKey("FoodCategory") && foodItem["FoodCategory"] == "Junk";

      if (isJunkItem) {
        print("Selected food item is Junk. Showing warning...");

        if (!parentContext.mounted) return;

        showDialog(
          context: parentContext,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text("Junk Food Alert!"),
              content: Text(
                "The food item you selected is categorized as junk food. Consider choosing a healthier option!",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HealthyItems()), // Redirect to healthy options
                    );
                  },
                  child: Text("Choose Healthy"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    onCheckout(); // Allow checkout despite warning
                  },
                  child: Text("Order Anyways"),
                ),
              ],
            );
          },
        );
        return;
      }

      // ✅ No restriction, allow checkout
      print("✅ No junk order restriction! Proceeding to checkout...");
      onCheckout();
    } catch (e) {
      print("❌ Error checking orders: $e");

      if (!parentContext.mounted) return;

      ScaffoldMessenger.of(parentContext).showSnackBar(SnackBar(
        content: Text("Error checking orders. Please try again."),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                "Customize ${widget.foodItem['name']}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),

              // Select Ingredients
              Text("Select Ingredients:", style: TextStyle(fontWeight: FontWeight.bold)),
              Column(
                children: (widget.foodItem['optionalIngredients'] as List).map<Widget>((ingredient) {
                  return CheckboxListTile(
                    title: Text(ingredient),
                    value: selectedIngredients.contains(ingredient),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedIngredients.add(ingredient);
                        } else {
                          selectedIngredients.remove(ingredient);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              SizedBox(height: 10),
              Text("Select Spice Level:", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: selectedSpiceLevel,
                onChanged: (newValue) {
                  setState(() {
                    selectedSpiceLevel = newValue!;
                  });
                },
                items: (widget.foodItem['spiceLevels'] as List).map<DropdownMenuItem<String>>((level) {
                  return DropdownMenuItem<String>(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
              ),

              SizedBox(height: 10),

              // Custom Instructions
              Text("Special Instructions:", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                decoration: InputDecoration(hintText: "E.g. No onions, extra cheese..."),
                onChanged: (value) {
                  setState(() {
                    customInstructions = value;
                  });
                },
              ),

              SizedBox(height: 15),

              // Buttons: Cancel and Add to Cart
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cancel Button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel", style: TextStyle(color: Colors.red)),
                  ),
                  TextButton(
                    child: Text("Proceed", style: TextStyle(color: Colors.red)),
                    onPressed: () async {
                      if (id != null) {
                        await junkCheck(context, id!, widget.foodItem, () {
                          Navigator.pop(context);
                          Future.delayed(Duration(milliseconds: 80), () {
                            showSubscribeDialog(widget.foodItem, customInstructions);
                          });
                        });
                      } else {
                        // Handle null case (e.g., show an error message)
                        print("Error: ID is null!");
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
  }
}
