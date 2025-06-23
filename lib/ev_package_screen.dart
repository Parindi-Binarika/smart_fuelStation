import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'charging_screen.dart';

class EVPackageScreen extends StatelessWidget {
  final List<Map<String, dynamic>> evPackages = [
    {'label': 'EV Package A - 30 mins', 'price': 'LKR 500', 'duration': 1},
    {'label': 'EV Package B - 1 hour', 'price': 'LKR 900', 'duration': 60},
    {'label': 'EV Package C - 2 hours', 'price': 'LKR 1700', 'duration': 120},
  ];

  void handleEVPayment(BuildContext context, Map<String, dynamic> pkg) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You must be logged in to continue.")),
      );
      return;
    }

    try {
      // 1. Add order to Firestore
      DocumentReference orderRef = await FirebaseFirestore.instance.collection('orders').add({
        'userId': user.uid,
        'package': pkg['label'],
        'price': pkg['price'],
        'duration': pkg['duration'],
        'type': 'EV',
        'status': 'Charging',
        'timestamp': Timestamp.now(),
      });

      // 2. Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment successful. Charging started.')),
      );

      // 3. Navigate to Charging Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChargingScreen(
            durationMinutes: pkg['duration'],
            orderId: orderRef.id,
          ),
        ),
      );
    } catch (e) {
      print("Firestore Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start charging: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('EV Charging Packages'),
        backgroundColor: Colors.teal,
      ),
      body: ListView.builder(
        itemCount: evPackages.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final pkg = evPackages[index];
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.ev_station, color: Colors.teal),
              title: Text(pkg['label'], style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(pkg['price']),
              trailing: ElevatedButton(
                onPressed: () => handleEVPayment(context, pkg),
                child: Text("Pay"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
            ),
          );
        },
      ),
    );
  }
}
