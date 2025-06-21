import 'package:flutter/material.dart';
import 'history_screen.dart';
import 'packages_screen.dart';

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _dashboardButton(
              context: context,
              label: "Select Your Package",
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
              label: "View History",
              icon: Icons.history,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => HistoryScreen()),
                );
              },
            ),
          ],
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
