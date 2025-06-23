import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class EVChartScreen extends StatefulWidget {
  @override
  _EVChartScreenState createState() => _EVChartScreenState();
}

class _EVChartScreenState extends State<EVChartScreen> {
  Map<String, int> chartData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChartData();
  }

  void fetchChartData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .where('type', isEqualTo: 'EV')
        .get();

    final Map<String, int> dataMap = {};
    for (var doc in snapshot.docs) {
  final data = doc.data() as Map<String, dynamic>;
  final label = data['package'] ?? 'Unknown';
  final durationRaw = data['duration'];
  final int duration = (durationRaw is int)
      ? durationRaw
      : int.tryParse(durationRaw.toString()) ?? 0;

  dataMap[label] = (dataMap[label] ?? 0) + duration;
}


    setState(() {
      chartData = dataMap;
      isLoading = false;
    });
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
        child: Text(keys[value.toInt()], style: TextStyle(fontSize: 10)),
      );
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("EV Charging Chart"),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text("Total Charging Duration per Package (in minutes)",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        barGroups: getChartGroups(),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: buildBottomTitles,
                            ),
                          ),
                        ),
                        gridData: FlGridData(show: false),
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
