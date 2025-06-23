import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'history_screen.dart';
import 'packages_screen.dart';
import 'ev_package_screen.dart';
import 'ev_history_screen.dart';
import 'chart_view_screen.dart';
import 'ev_chart_screen.dart';
import 'login_screen.dart'; // Make sure this is your login screen

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F4C5C),
      appBar: AppBar(
        title: const Text("Smart Charging Station"),
        backgroundColor: Colors.teal[800],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dashboardButton(
                context: context,
                label: "Select Mobile Charging Package",
                icon: Icons.bolt,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PackagesScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),
              _dashboardButton(
                context: context,
                label: "Mobile Charging History",
                icon: Icons.history,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HistoryScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),
              _dashboardButton(
                context: context,
                label: "Mobile Charging Chart",
                icon: Icons.bar_chart,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChartViewScreen()),
                  );
                },
              ),
              const Divider(height: 40, color: Colors.white),
              _dashboardButton(
                context: context,
                label: "Select EV Charging Package",
                icon: Icons.electric_car,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EVPackageScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),
              _dashboardButton(
                context: context,
                label: "EV Charging History",
                icon: Icons.ev_station,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EVHistoryScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),
              _dashboardButton(
                context: context,
                label: "EV Charging Chart",
                icon: Icons.insights,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EVChartScreen()),
                  );
                },
              ),
              Align(
  alignment: Alignment.centerRight,
  child: ElevatedButton.icon(
    icon: Icon(Icons.logout, size: 18),
    label: Text("Logout", style: TextStyle(fontSize: 14)),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.redAccent,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    onPressed: () async {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    },
  ),
),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboardButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 28),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
