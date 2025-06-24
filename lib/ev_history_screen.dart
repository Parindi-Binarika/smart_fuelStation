import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'ev_chart_screen.dart';

class EVHistoryScreen extends StatefulWidget {
  const EVHistoryScreen({super.key});

  @override
  EVHistoryScreenState createState() => EVHistoryScreenState();
}

class EVHistoryScreenState extends State<EVHistoryScreen> {
  List<Map<String, dynamic>> evOrders = [];
  bool isLoading = true;
  String sortOption = 'Latest';
  DatabaseReference? _evOrdersRef;
  StreamSubscription<DatabaseEvent>? _evOrdersSubscription;

  @override
  void initState() {
    super.initState();
    fetchEVOrders();
    // Remove syncRealtimeToFirestore as it's causing conflicts
  }

  @override
  void dispose() {
    _evOrdersSubscription?.cancel();
    super.dispose();
  }

  void fetchEVOrders() async {
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'EV')
          .get();

      final List<Map<String, dynamic>> loadedOrders = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'package': data['package'] ?? 'N/A',
          'status': data['status'] ?? 'N/A',
          'price': data['price'] ?? 'N/A',
          'duration': data['duration'] ?? 0,
          'timestamp': (data['timestamp'] is Timestamp)
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.tryParse(data['timestamp']?.toString() ?? '') ?? DateTime.now(),
        };
      }).toList();

      loadedOrders.sort((a, b) => sortOption == 'Latest'
          ? b['timestamp'].compareTo(a['timestamp'])
          : a['timestamp'].compareTo(b['timestamp']));

      if (mounted) {
        setState(() {
          evOrders = loadedOrders;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load EV history: $e")),
        );
      }
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd • hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EV Charging History'),
        backgroundColor: Colors.teal,
        actions: [
          DropdownButton<String>(
            value: sortOption,
            underline: const SizedBox(),
            dropdownColor: Colors.teal[50],
            icon: const Icon(Icons.sort, color: Colors.white),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  sortOption = value;
                  isLoading = true;
                });
                fetchEVOrders();
              }
            },
            items: ['Latest', 'Oldest'].map((sort) {
              return DropdownMenuItem(
                value: sort,
                child: Text(sort),
              );
            }).toList(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : evOrders.isEmpty
              ? const Center(child: Text('No EV charging history found.'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: evOrders.length,
                        itemBuilder: (context, index) {
                          final order = evOrders[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.ev_station, color: Colors.teal),
                              title: Text(order['package'],
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text("Status: ${order['status']}"),
                                  Text("Price: ${order['price']}"),
                                  Text("Duration: ${order['duration']} mins"),
                                  const SizedBox(height: 2),
                                  Text("Date: ${formatDate(order['timestamp'])}"),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EVChartScreen()),
                          );
                        },
                        icon: const Icon(Icons.bar_chart),
                        label: const Text('Chart View'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[700],
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}