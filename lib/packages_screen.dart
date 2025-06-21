import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'charging_screen.dart';

class PackagesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> packages = [
    {'label': 'Package 1 - 15 mins', 'duration': 1, 'price': 100},
    {'label': 'Package 2 - 30 mins', 'duration': 2, 'price': 200},
    {'label': 'Package 3 - 60 mins', 'duration': 60, 'price': 400},
  ];

  void handlePaymentAndOrder(BuildContext context, String label, int duration, int price) async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? "unknown_user";

      DocumentReference orderRef = await FirebaseFirestore.instance.collection('orders').add({
        'userId': userId,
        'package': label,
        'duration': duration,
        'price': price,
        'status': 'Charging Started',
        'timestamp': Timestamp.now(),
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChargingScreen(
            durationMinutes: duration,
            orderId: orderRef.id, // Pass the Firestore document ID
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to start charging: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Charging Package"),
        backgroundColor: Colors.teal,
        leading: BackButton(color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: packages.length,
        itemBuilder: (context, index) {
          final package = packages[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: Icon(Icons.ev_station, color: Colors.teal, size: 32),
              title: Text(package['label'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              subtitle: Text("Price: Rs.${package['price']}"),
              trailing: ElevatedButton(
                onPressed: () => handlePaymentAndOrder(
                  context,
                  package['label'],
                  package['duration'],
                  package['price'],
                ),
                child: Text("Pay"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
