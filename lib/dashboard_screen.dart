// dashboard_screen.dart
import 'package:flutter/material.dart';
//import 'package:smart_fuel/screens/history_screen.dart';
//import 'package:smart_fuel/screens/packages_screen.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F4C5C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // ElevatedButton(
            //   onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PackagesScreen())),
            //   child: Text('Packages'),
            // ),
            // ElevatedButton(
            //   onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryScreen())),
            //   child: Text('History'),
            // ),
            
          ],
        ),
      ),
    );
  }
}
