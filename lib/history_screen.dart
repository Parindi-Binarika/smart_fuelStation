import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'chart_view_screen.dart';

// mobile history_screen (only Mobile history)
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  HistoryScreenState createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  String sortOption = 'Latest';

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  void fetchOrders() async {
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User is not logged in.');

      bool isDescending = sortOption == 'Latest';

      print("Fetching orders for $userId with sort: $sortOption, filter: Mobile");

      Query query = FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'Mobile');

      QuerySnapshot snapshot = await query
          .orderBy('timestamp', descending: isDescending)
          .get();

      print("Orders fetched: ${snapshot.docs.length}");

      final List<Map<String, dynamic>> loadedOrders = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'package': data['package'] ?? 'N/A',
          'status': data['status'] ?? 'N/A',
          'type': data['type'] ?? 'Mobile',
          'price': data['price'] ?? 'N/A',
          'duration': data['duration'] ?? 0,
          'timestamp': (data['timestamp'] as Timestamp).toDate(),
        };
      }).toList();

      setState(() {
        orders = loadedOrders;
        isLoading = false;
      });
    } catch (e) {
      print('Firestore error: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading orders: $e")),
      );
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd • hh:mm a').format(date);
  }

  Icon getTypeIcon(String type) {
    // Only Mobile type is shown
    return const Icon(Icons.phone_android, color: Colors.teal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Charging History'),
        backgroundColor: Colors.teal,
        actions: [
          // Sort dropdown only
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
                fetchOrders();
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
          : orders.isEmpty
              ? const Center(
                  child: Text('No mobile charging history found.'),
                )
              : Column(
                  children: [
                    // Summary card
                    if (orders.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.teal[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.withAlpha((0.3 * 255).toInt())),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '${orders.length}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                                const Text('Total Sessions'),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  '${orders.fold<int>(0, (sum, order) => sum + (order['duration'] as int))}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                                const Text('Total Minutes'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: getTypeIcon(order['type']),
                              title: Text(
                                order['package'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text("Status: ${order['status']}"),
                                  Text("Price: Rs.${order['price']}"),
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
                            MaterialPageRoute(builder: (_) => const ChartViewScreen()),
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
