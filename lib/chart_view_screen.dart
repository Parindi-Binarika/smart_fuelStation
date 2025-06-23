import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
// mobile chart_view_screen
class ChartViewScreen extends StatefulWidget {
  @override
  _ChartViewScreenState createState() => _ChartViewScreenState();
}

class _ChartViewScreenState extends State<ChartViewScreen> {
  Map<String, int> packageCounts = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChartData();
  }

  void fetchChartData() async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .get();

    final Map<String, int> counts = {};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final pkg = data['package'] ?? 'Unknown';
      counts[pkg] = (counts[pkg] ?? 0) + 1;
    }

    setState(() {
      packageCounts = counts;
      isLoading = false;
    });
  }

  List<BarChartGroupData> getBarGroups() {
    int i = 0;
    return packageCounts.entries.map((entry) {
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
    if (value.toInt() >= packageCounts.length) return Text('');
    final pkgName = packageCounts.keys.elementAt(value.toInt());
    return Text(pkgName, style: TextStyle(fontSize: 10), textAlign: TextAlign.center);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Charging Chart'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: BarChart(
                BarChartData(
                  barGroups: getBarGroups(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: bottomTitles,
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                ),
              ),
            ),
    );
  }
}
