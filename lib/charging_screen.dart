import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChargingScreen extends StatefulWidget {
  final int durationMinutes;
  final String orderId;

  ChargingScreen({required this.durationMinutes, required this.orderId});

  @override
  _ChargingScreenState createState() => _ChargingScreenState();
}

class _ChargingScreenState extends State<ChargingScreen> {
  late int remainingSeconds;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    remainingSeconds = widget.durationMinutes * 60;
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (remainingSeconds <= 1) {
        t.cancel();
        setState(() => remainingSeconds = 0);
        completeCharging();
      } else {
        setState(() => remainingSeconds--);
      }
    });
  }

  Future<void> completeCharging() async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({'status': 'Charging Done'});

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Charging Completed"),
          content: Text("Your charging session has ended."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back to previous screen
              },
              child: Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating status: $e")),
      );
    }
  }

  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Charging"),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.battery_charging_full, size: 100, color: Colors.teal),
            SizedBox(height: 20),
            Text(
              "Charging in Progress",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              formatTime(remainingSeconds),
              style: TextStyle(fontSize: 48, color: Colors.teal),
            ),
          ],
        ),
      ),
    );
  }
}
