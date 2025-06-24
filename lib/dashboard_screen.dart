import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'history_screen.dart';
import 'packages_screen.dart';
import 'ev_package_screen.dart';
import 'ev_history_screen.dart';
import 'chart_view_screen.dart';
import 'ev_chart_screen.dart';
import 'login_screen.dart';
import 'port_availability_service.dart';
import 'port_status_widget.dart';
import 'widgets/dashboard_charging_widget.dart'; // Add this import at the top

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // Add a GlobalKey to control the charging widget
  final GlobalKey<DashboardChargingWidgetState> _chargingWidgetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Initialize ports when dashboard loads
    PortAvailabilityService.initializePorts();
  }

  List<Widget> get _pages => [
    _DashboardHomeScreen(chargingWidgetKey: _chargingWidgetKey),
    const PackagesScreen(),
    const HistoryScreen(),
    const ChartViewScreen(),
    EVPackageScreen(),
    const EVHistoryScreen(),
    const EVChartScreen(),
  ];

  final List<String> _titles = [
    "Dashboard",
    "Select Mobile Charging Package",
    "Mobile Charging History",
    "Mobile Charging Chart",
    "Select EV Charging Package",
    "EV Charging History",
    "EV Charging Chart",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F4C5C),
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.teal[800],
        elevation: 0,
        actions: [
          // Show current charging status in app bar if user has active session
          if (currentUserId != null)
            StreamBuilder<DocumentSnapshot?>(
              stream: Stream.fromFuture(PortAvailabilityService.getUserActiveSession(currentUserId!))
                  .asyncExpand((session) => session != null 
                      ? Stream.periodic(const Duration(seconds: 5), (_) => PortAvailabilityService.getUserActiveSession(currentUserId!)).asyncMap((future) => future)
                      : Stream.value(null)),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Charging',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.teal[800],
              ),
              child: const Text(
                'Smart Charging Station',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _drawerItem(
              icon: Icons.dashboard,
              text: 'Dashboard',
              index: 0,
            ),
            const Divider(),
            _drawerItem(
              icon: Icons.bolt,
              text: 'Select Mobile Charging Package',
              index: 1,
            ),
            _drawerItem(
              icon: Icons.history,
              text: 'Mobile Charging History',
              index: 2,
            ),
            _drawerItem(
              icon: Icons.bar_chart,
              text: 'Mobile Charging Chart',
              index: 3,
            ),
            const Divider(),
            _drawerItem(
              icon: Icons.electric_car,
              text: 'Select EV Charging Package',
              index: 4,
            ),
            _drawerItem(
              icon: Icons.ev_station,
              text: 'EV Charging History',
              index: 5,
            ),
            _drawerItem(
              icon: Icons.insights,
              text: 'EV Charging Chart',
              index: 6,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Show countdown if charging
          DashboardChargingWidget(
            key: _chargingWidgetKey,
            onChargingComplete: () {
              setState(() {});
            },
          ),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _drawerItem({required IconData icon, required String text, required int index}) {
    return ListTile(
      leading: Icon(icon, color: _selectedIndex == index ? Colors.teal[800] : null),
      title: Text(text),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context); // Close the drawer
      },
    );
  }
}

class _DashboardHomeScreen extends StatelessWidget {
  final GlobalKey<DashboardChargingWidgetState> chargingWidgetKey;

  const _DashboardHomeScreen({Key? key, required this.chargingWidgetKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal[700]!, Colors.teal[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to Smart Charging Station',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Monitor port availability and manage your charging sessions',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Port availability section
          const Text(
            'Port Availability',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          const PortStatusWidget(
            portType: PortAvailabilityService.MOBILE_PORT,
            displayName: 'Mobile Charging Ports',
          ),
          
          const PortStatusWidget(
            portType: PortAvailabilityService.EV_PORT,
            displayName: 'EV Charging Ports',
          ),
          
          const SizedBox(height: 24),
          
          // Current session section
          if (currentUserId != null)
            FutureBuilder<DocumentSnapshot?>(
              future: PortAvailabilityService.getUserActiveSession(currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasData && snapshot.data != null) {
                  final session = snapshot.data!;
                  final sessionData = session.data() as Map<String, dynamic>;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Charging Session',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          border: Border.all(color: Colors.orange),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  sessionData['portType'] == PortAvailabilityService.MOBILE_PORT
                                      ? Icons.smartphone
                                      : Icons.electric_car,
                                  color: Colors.orange,
                                  size: 30,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Port: ${sessionData['portId']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Package: ${sessionData['packageName']}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Stop Charging'),
                                    content: const Text('Are you sure you want to stop the current charging session?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text('Stop Charging'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirmed == true) {
                                  await PortAvailabilityService.releasePort(
                                    sessionData['portId'],
                                    currentUserId,
                                  );
                                  
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Charging session stopped successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Stop Charging'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                
                return const SizedBox.shrink();
              },
            ),
          
          const SizedBox(height: 24),
          
          // Quick actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.smartphone,
                  title: 'Mobile Charging',
                  subtitle: 'Select mobile package',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PackagesScreen(
                          chargingWidgetKey: chargingWidgetKey,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.electric_car,
                  title: 'EV Charging',
                  subtitle: 'Select EV package',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EVPackageScreen(
                          chargingWidgetKey: chargingWidgetKey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.teal[800],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}