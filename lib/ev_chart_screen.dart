import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class EVChartScreen extends StatefulWidget {
  const EVChartScreen({super.key});

  @override
  EVChartScreenState createState() => EVChartScreenState();
}

class EVChartScreenState extends State<EVChartScreen> {
  Map<String, int> chartData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChartData();
  }

  Future<void> fetchChartData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Fetch data from Firestore instead of Realtime DB
      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'EV')
          .get();

      final Map<String, int> dataMap = {};
      
      for (final doc in querySnapshot.docs) {
        final order = doc.data();
        final label = order['package'] ?? 'Unknown';
        final raw = order['duration'];
        final int duration = (raw is int)
            ? raw
            : int.tryParse(raw.toString()) ?? 0;

        dataMap[label] = (dataMap[label] ?? 0) + duration;
      }

      setState(() {
        chartData = dataMap;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chart data: $e')),
        );
      }
    }
  }

  List<BarChartGroupData> getChartGroups() {
    int i = 0;
    return chartData.entries.map((entry) {
      return BarChartGroupData(
        x: i++,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            width: 20,
            color: Colors.teal,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  Widget buildBottomTitles(double value, TitleMeta meta) {
    final keys = chartData.keys.toList();
    if (value.toInt() < keys.length) {
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(
          keys[value.toInt()].split(' - ')[0], // Show package name only
          style: const TextStyle(fontSize: 10),
        ),
      );
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("EV Charging Chart"),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : chartData.isEmpty
              ? const Center(child: Text('No charging data available'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        "Total Charging Duration per Package (in minutes)",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            barGroups: getChartGroups(),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: true),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: buildBottomTitles,
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
    );
  }
}