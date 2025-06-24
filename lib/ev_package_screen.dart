import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'port_availability_service.dart';
import 'services/charging_service.dart'; // Add this import
import 'widgets/dashboard_charging_widget.dart';

class EVPackageScreen extends StatefulWidget {
  final GlobalKey<DashboardChargingWidgetState>? chargingWidgetKey;
  const EVPackageScreen({super.key, this.chargingWidgetKey});

  @override
  _EVPackageScreenState createState() => _EVPackageScreenState();
}

class _EVPackageScreenState extends State<EVPackageScreen> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  bool _isLoading = false;

  final List<Map<String, dynamic>> evPackages = [
    {
      'name': 'EV Basic',
      'price': 300,
      'duration': '1 hour',
      'description': 'Perfect for quick EV charging',
      'features': [
        'AC charging',
        '2 hour duration',
        'Standard support',
        'Up to 30kW',
      ],
    },
    {
      'name': 'EV Standard',
      'price': 600,
      'duration': '4 hours',
      'description': 'Ideal for extended EV charging',
      'features': [
        'DC fast charging',
        '4 hour duration',
        'Priority support',
        'Up to 50kW',
        'Usage analytics',
      ],
    },
    {
      'name': 'EV Premium',
      'price': 1200,
      'duration': '8 hours',
      'description': 'Best for overnight charging',
      'features': [
        'Ultra-fast DC charging',
        '8 hour duration',
        '24/7 support',
        'Up to 100kW',
        'Detailed analytics',
        'Booking priority',
      ],
    },
  ];

  Future<void> _selectEVPackage(Map<String, dynamic> package) async {
    if (currentUserId == null) {
      _showErrorDialog('Please log in to select a package.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user already has an active session
      final hasActive = await PortAvailabilityService.hasActiveSession(
        currentUserId!,
      );
      if (hasActive) {
        _showErrorDialog(
          'You already have an active charging session. Please complete it before starting a new one.',
        );
        return;
      }

      // Check if EV charging port is available
      final isAvailable = await PortAvailabilityService.isPortTypeAvailable(
        PortAvailabilityService.EV_PORT,
      );

      if (!isAvailable) {
        _showErrorDialog(
          'No EV charging ports are currently available. Please try again later.',
        );
        return;
      }

      // Show confirmation dialog
      final confirmed = await _showConfirmationDialog(package);
      if (!confirmed) return;

      // Reserve the port
      final portId = await PortAvailabilityService.reservePort(
        PortAvailabilityService.EV_PORT,
        currentUserId!,
        package['name'],
      );

      if (portId != null) {
        // Create order in Realtime DB and Firestore, then start countdown
        final result = await ChargingService.createOrderAndStartCharging(
          userId: currentUserId!,
          package: package,
          portId: portId,
          portType: PortAvailabilityService.EV_PORT,
          chargingWidgetKey: widget.chargingWidgetKey, // Pass the key here
        );
        if (result == null) {
          _showErrorDialog('Failed to start charging. Please try again.');
        } else {
          _showSuccessDialog(package, portId);
        }
        return;
      } else {
        _showErrorDialog(
          'Failed to reserve EV charging port. Please try again.',
        );
      }
    } catch (e) {
      _showErrorDialog('An error occurred: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _showConfirmationDialog(Map<String, dynamic> package) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Confirm ${package['name']}'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Package: ${package['name']}'),
                    Text('Price: \$${package['price']}'),
                    Text('Duration: ${package['duration']}'),
                    const SizedBox(height: 10),
                    const Text(
                      'Are you sure you want to start this EV charging session?',
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[800],
                    ),
                    child: const Text('Confirm'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  void _showSuccessDialog(Map<String, dynamic> package, String portId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('EV Charging Started!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.electric_car, color: Colors.green, size: 48),
                const SizedBox(height: 16),
                Text('Package: ${package['name']}'),
                Text('Port: $portId'),
                Text('Duration: ${package['duration']}'),
                const SizedBox(height: 10),
                const Text(
                  'Your EV charging session has started successfully!',
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[800],
                ),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F4C5C), Color(0xFF1A6B7A)],
          ),
        ),
        child: Column(
          children: [
            // Port availability status
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: PortAvailabilityService.getPortsByTypeStream(
                  PortAvailabilityService.EV_PORT,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Row(
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(width: 16),
                        Text(
                          'Checking port availability...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    );
                  }

                  if (snapshot.hasError) {
                    return const Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 16),
                        Text(
                          'Error checking availability',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    );
                  }

                  final ports = snapshot.data?.docs ?? [];
                  final availablePorts =
                      ports.where((port) => port['isAvailable'] == true).length;
                  final totalPorts = ports.length;
                  final hasAvailable = availablePorts > 0;

                  return Row(
                    children: [
                      Icon(
                        hasAvailable ? Icons.check_circle : Icons.cancel,
                        color: hasAvailable ? Colors.green : Colors.red,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'EV Charging Ports',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Available: $availablePorts / $totalPorts',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: hasAvailable ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          hasAvailable ? 'Available' : 'All Busy',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Active session warning
            if (currentUserId != null)
              FutureBuilder<bool>(
                future: PortAvailabilityService.hasActiveSession(
                  currentUserId!,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data == true) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You have an active charging session. Complete it before selecting a new package.',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

            const SizedBox(height: 16),

            // EV Packages list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: evPackages.length,
                itemBuilder: (context, index) {
                  final package = evPackages[index];
                  return _EVPackageCard(
                    package: package,
                    onSelect: () => _selectEVPackage(package),
                    isLoading: _isLoading,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EVPackageCard extends StatelessWidget {
  final Map<String, dynamic> package;
  final VoidCallback onSelect;
  final bool isLoading;

  const _EVPackageCard({
    required this.package,
    required this.onSelect,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.blue.shade50],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.electric_car, color: Colors.blue[800], size: 28),
                    const SizedBox(width: 8),
                    Text(
                      package['name'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F4C5C),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[800],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$${package['price']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              package['description'],
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.blue[800], size: 20),
                const SizedBox(width: 8),
                Text(
                  package['duration'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0F4C5C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Features:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            ...package['features']
                .map<Widget>(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.electric_bolt,
                          color: Colors.blue[700],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          feature,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            const SizedBox(height: 20),

            // Port availability check for button
            StreamBuilder<QuerySnapshot>(
              stream: PortAvailabilityService.getPortsByTypeStream(
                PortAvailabilityService.EV_PORT,
              ),
              builder: (context, snapshot) {
                final ports = snapshot.data?.docs ?? [];
                final hasAvailable = ports.any(
                  (port) => port['isAvailable'] == true,
                );

                return FutureBuilder<bool>(
                  future:
                      currentUserId != null
                          ? PortAvailabilityService.hasActiveSession(
                            currentUserId,
                          )
                          : Future.value(false),
                  builder: (context, activeSessionSnapshot) {
                    final hasActiveSession =
                        activeSessionSnapshot.data ?? false;
                    final canSelect =
                        hasAvailable && !hasActiveSession && !isLoading;

                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: canSelect ? onSelect : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              canSelect ? Colors.blue[800] : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: canSelect ? 4 : 0,
                        ),
                        child:
                            isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  !hasAvailable
                                      ? 'No EV Ports Available'
                                      : hasActiveSession
                                      ? 'Session Active'
                                      : 'Select EV Package',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
