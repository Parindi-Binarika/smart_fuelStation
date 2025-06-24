import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChargingScreen extends StatefulWidget {
  final int durationMinutes;
  final String orderId;
  final String firestoreId;

  const ChargingScreen({
    super.key,
    required this.durationMinutes,
    required this.orderId,
    required this.firestoreId,
  });

  @override
  ChargingScreenState createState() => ChargingScreenState();
}

class ChargingScreenState extends State<ChargingScreen> {
  int remainingSeconds = 60; // 1 min for development
  Timer? _timer;
  bool isCharging = true;

  @override
  void initState() {
    super.initState();
    remainingSeconds = widget.durationMinutes * 60;
    startCharging();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startCharging() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        if (remainingSeconds > 0) {
          remainingSeconds--;
        } else {
          isCharging = false;
          timer.cancel();
          _completeCharging();
        }
      });
    });
  }

  Future<void> _completeCharging() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // ✅ Update Realtime Database
      await FirebaseDatabase.instance
          .ref()
          .child('orders/${widget.orderId}')
          .update({
        'status': 'Completed',
        'completedAt': DateTime.now().toIso8601String(),
      });

      // ✅ Update Firestore document
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.firestoreId)
          .update({
        'status': 'Completed',
        'completedAt': Timestamp.now(),
      });

      if (mounted) {
        _showCompletionDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Charging Complete!'),
        content: const Text('Your EV has been successfully charged.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = ((widget.durationMinutes * 60 - remainingSeconds) /
        (widget.durationMinutes * 60));

    return Scaffold(
      appBar: AppBar(
        title: const Text('EV Charging'),
        backgroundColor: Colors.teal,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCharging ? Icons.ev_station : Icons.check_circle,
              size: 100,
              color: isCharging ? Colors.teal : Colors.green,
            ),
            const SizedBox(height: 20),
            Text(
              isCharging ? 'Charging in Progress...' : 'Charging Complete!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (isCharging) ...[
              Text(
                'Time Remaining: ${formatTime(remainingSeconds)}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
              const SizedBox(height: 20),
              Text('${(progress * 100).toInt()}% Complete',
                  style: const TextStyle(fontSize: 16)),
            ],
          ],
        ),
      ),
    );
  }
}
