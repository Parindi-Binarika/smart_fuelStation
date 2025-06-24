import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

// mobile chart_view_screen
class ChartViewScreen extends StatefulWidget {
  const ChartViewScreen({super.key});

  @override
  ChartViewScreenState createState() => ChartViewScreenState();
}

class ChartViewScreenState extends State<ChartViewScreen> {
  Map<String, int> packageCounts = {};
  Map<String, int> durationTotals = {};
  bool isLoading = true;
  String chartType = 'Count'; // 'Count' or 'Duration'

  @override
  void initState() {
    super.initState();
    fetchChartData();
  }

  void fetchChartData() async {
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() => isLoading = false);
        return;
      }

      // Fetch only Mobile orders for the user
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'Mobile')
          .get();

      final Map<String, int> counts = {};
      final Map<String, int> durations = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final pkg = data['package'] ?? 'Unknown';
        final duration = data['duration'] ?? 0;
        final durationInt = (duration is int) ? duration : int.tryParse(duration.toString()) ?? 0;

        // Count occurrences
        counts[pkg] = (counts[pkg] ?? 0) + 1;

        // Sum durations
        durations[pkg] = (durations[pkg] ?? 0) + durationInt;
      }

      setState(() {
        packageCounts = counts;
        durationTotals = durations;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chart data: $e')),
        );
      }
    }
  }

  List<BarChartGroupData> getBarGroups() {
    final dataMap = chartType == 'Count' ? packageCounts : durationTotals;
    int i = 0;
    return dataMap.entries.map((entry) {
      return BarChartGroupData(
        x: i++,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: Colors.teal,
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    final dataMap = chartType == 'Count' ? packageCounts : durationTotals;
    if (value.toInt() >= dataMap.length) return const Text('');
    final pkgName = dataMap.keys.elementAt(value.toInt());
    final shortName = pkgName.split(' - ')[0];
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        shortName,
        style: const TextStyle(fontSize: 10),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Charging Chart'),
        backgroundColor: Colors.teal,
        actions: [
          DropdownButton<String>(
            value: chartType,
            underline: const SizedBox(),
            dropdownColor: Colors.teal[50],
            icon: const Icon(Icons.analytics, color: Colors.white),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  chartType = value;
                });
              }
            },
            items: ['Count', 'Duration'].map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (packageCounts.isEmpty && durationTotals.isEmpty)
              ? const Center(child: Text('No mobile charging data available'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        chartType == 'Count'
                            ? 'Number of Mobile Charging Sessions per Package'
                            : 'Total Mobile Charging Duration per Package (in minutes)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            barGroups: getBarGroups(),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: true),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: bottomTitles,
                                  reservedSize: 40,
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: const FlGridData(show: false),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
