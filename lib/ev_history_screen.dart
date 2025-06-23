import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'ev_chart_screen.dart';

class EVHistoryScreen extends StatefulWidget {
  @override
  _EVHistoryScreenState createState() => _EVHistoryScreenState();
}

class _EVHistoryScreenState extends State<EVHistoryScreen> {
  List<Map<String, dynamic>> evOrders = [];
  bool isLoading = true;
  String sortOption = 'Latest';

  @override
  void initState() {
    super.initState();
    fetchEVOrders();
  }

  void fetchEVOrders() async {
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User is not logged in.');

      bool isDescending = sortOption == 'Latest';

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'EV')
          .orderBy('timestamp', descending: isDescending)
          .get();

      final List<Map<String, dynamic>> loadedOrders = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'package': data['package'] ?? 'N/A',
          'status': data['status'] ?? 'N/A',
          'timestamp': (data['timestamp'] as Timestamp).toDate(),
        };
      }).toList();

      setState(() {
        evOrders = loadedOrders;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading EV orders: $e")),
      );
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd • hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('EV Charging History'),
        backgroundColor: Colors.teal,
        actions: [
          DropdownButton<String>(
            value: sortOption,
            underline: SizedBox(),
            dropdownColor: Colors.teal[50],
            icon: Icon(Icons.sort, color: Colors.white),
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
          ? Center(child: CircularProgressIndicator())
          : evOrders.isEmpty
              ? Center(child: Text('No EV charging history found.'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: evOrders.length,
                        itemBuilder: (context, index) {
                          final order = evOrders[index];
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Icon(Icons.ev_station, color: Colors.teal),
                              title: Text(order['package'],
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text("Status: ${order['status']}"),
                                  SizedBox(height: 2),
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
                            MaterialPageRoute(builder: (_) => EVChartScreen()),
                          );
                        },
                        icon: Icon(Icons.bar_chart),
                        label: Text('Chart View'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[700],
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
