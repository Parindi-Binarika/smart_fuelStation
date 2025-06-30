import 'package:cloud_firestore/cloud_firestore.dart';

class PortAvailabilityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _portsCollection = 'charging_ports';
  static const String _sessionsCollection = 'charging_sessions';

  // Port types
  static const String MOBILE_PORT = 'mobile';
  static const String EV_PORT = 'ev';

  // Initialize ports in Firestore (call this once when setting up the system)
  static Future<void> initializePorts() async {
    try {
      final portsRef = _firestore.collection(_portsCollection);

      // Define all port configs
      final ports = [
        {
          'id': 'mobile_port_1',
          'type': MOBILE_PORT,
          'name': 'Mobile Charging Port 1',
        },
        {
          'id': 'mobile_port_2',
          'type': MOBILE_PORT,
          'name': 'Mobile Charging Port 2',
        },
        {'id': 'ev_port_1', 'type': EV_PORT, 'name': 'EV Charging Port 1'},
        {'id': 'ev_port_2', 'type': EV_PORT, 'name': 'EV Charging Port 2'},
      ];

      for (final port in ports) {
        final doc = await portsRef.doc(port['id']!).get();
        if (!doc.exists) {
          await portsRef.doc(port['id']!).set({
            'id': port['id'],
            'type': port['type'],
            'name': port['name'],
            'isAvailable': true,
            'currentUserId': null,
            'currentPackage': null,
            'sessionStartTime': null,
            'createdAt': FieldValue.serverTimestamp(),
          });
          print('Created ${port['id']}');
        }
      }

      print('Port initialization completed successfully');
    } catch (e) {
      print('Error initializing ports: $e');
      rethrow;
    }
  }

  // Alternative method to force recreate ports (use this if you need to reset)
  static Future<void> forceInitializePorts() async {
    try {
      final portsRef = _firestore.collection(_portsCollection);

      final ports = [
        {
          'id': 'mobile_port_1',
          'type': MOBILE_PORT,
          'name': 'Mobile Charging Port 1',
        },
        {
          'id': 'mobile_port_2',
          'type': MOBILE_PORT,
          'name': 'Mobile Charging Port 2',
        },
        {'id': 'ev_port_1', 'type': EV_PORT, 'name': 'EV Charging Port 1'},
        {'id': 'ev_port_2', 'type': EV_PORT, 'name': 'EV Charging Port 2'},
      ];

      for (final port in ports) {
        await portsRef.doc(port['id']!).set({
          'id': port['id'],
          'type': port['type'],
          'name': port['name'],
          'isAvailable': true,
          'currentUserId': null,
          'currentPackage': null,
          'sessionStartTime': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('Force created ${port['id']}');
      }

      print('Ports force initialized successfully');
    } catch (e) {
      print('Error force initializing ports: $e');
      rethrow;
    }
  }

  // Get port availability status with error handling
  static Stream<QuerySnapshot> getPortsStream() {
    return _firestore.collection(_portsCollection).snapshots();
  }

  // Get specific port type availability with error handling
  static Stream<QuerySnapshot> getPortsByTypeStream(String portType) {
    return _firestore
        .collection(_portsCollection)
        .where('type', isEqualTo: portType)
        .snapshots();
  }

  // Check if any port of specific type is available
  static Future<bool> isPortTypeAvailable(String portType) async {
    try {
      final snapshot =
          await _firestore
              .collection(_portsCollection)
              .where('type', isEqualTo: portType)
              .where('isAvailable', isEqualTo: true)
              .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking port availability: $e');
      return false;
    }
  }

  // Get available port of specific type
  static Future<DocumentSnapshot?> getAvailablePort(String portType) async {
    try {
      final snapshot =
          await _firestore
              .collection(_portsCollection)
              .where('type', isEqualTo: portType)
              .where('isAvailable', isEqualTo: true)
              .limit(1)
              .get();

      return snapshot.docs.isNotEmpty ? snapshot.docs.first : null;
    } catch (e) {
      print('Error getting available port: $e');
      return null;
    }
  }

  // Reserve a port for charging
  static Future<String?> reservePort(
    String portType,
    String userId,
    String packageName,
  ) async {
    try {
      final availablePort = await getAvailablePort(portType);
      if (availablePort == null) {
        print('No available port of type: $portType');
        return null;
      }

      // Update port status
      await _firestore
          .collection(_portsCollection)
          .doc(availablePort.id)
          .update({
            'isAvailable': false,
            'currentUserId': userId,
            'currentPackage': packageName,
            'sessionStartTime': FieldValue.serverTimestamp(),
          });

      // Create charging session record
      await _firestore.collection(_sessionsCollection).add({
        'portId': availablePort.id,
        'portType': portType,
        'userId': userId,
        'packageName': packageName,
        'startTime': FieldValue.serverTimestamp(),
        'endTime': null,
        'status': 'active',
        'isCompleted': false,
      });

      print('Port reserved successfully: ${availablePort.id}');
      return availablePort.id;
    } catch (e) {
      print('Error reserving port: $e');
      return null;
    }
  }

  // Release a port after charging is complete
  static Future<bool> releasePort(String portId, String userId) async {
    try {
      // Update port status
      await _firestore.collection(_portsCollection).doc(portId).update({
        'isAvailable': true,
        'currentUserId': null,
        'currentPackage': null,
        'sessionStartTime': null,
      });

      // Update charging session
      final sessionsQuery =
          await _firestore
              .collection(_sessionsCollection)
              .where('portId', isEqualTo: portId)
              .where('userId', isEqualTo: userId)
              .where('status', isEqualTo: 'active')
              .get();

      for (final doc in sessionsQuery.docs) {
        await doc.reference.update({
          'endTime': FieldValue.serverTimestamp(),
          'status': 'completed',
          'isCompleted': true,
        });
      }

      print('Port released successfully: $portId');
      return true;
    } catch (e) {
      print('Error releasing port: $e');
      return false;
    }
  }

  // Get user's current active session
  static Future<DocumentSnapshot?> getUserActiveSession(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection(_sessionsCollection)
              .where('userId', isEqualTo: userId)
              .where('status', isEqualTo: 'active')
              .limit(1)
              .get();

      return snapshot.docs.isNotEmpty ? snapshot.docs.first : null;
    } catch (e) {
      print('Error getting user active session: $e');
      return null;
    }
  }

  // Check if user has an active charging session
  static Future<bool> hasActiveSession(String userId) async {
    try {
      final session = await getUserActiveSession(userId);
      return session != null;
    } catch (e) {
      print('Error checking active session: $e');
      return false;
    }
  }

  // Get port details by ID
  static Future<DocumentSnapshot?> getPortById(String portId) async {
    try {
      final doc =
          await _firestore.collection(_portsCollection).doc(portId).get();
      return doc.exists ? doc : null;
    } catch (e) {
      print('Error getting port: $e');
      return null;
    }
  }

  // Get all charging sessions for a user
  static Stream<QuerySnapshot> getUserChargingSessions(String userId) {
    return _firestore
        .collection(_sessionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .snapshots();
  }

  // Debug method to check Firestore connection and data
  static Future<void> debugFirestoreConnection() async {
    try {
      print('Testing Firestore connection...');

      // Test basic connection
      final testDoc =
          await _firestore.collection(_portsCollection).limit(1).get();
      print('Firestore connection successful');
      print('Documents in ports collection: ${testDoc.docs.length}');

      // List all documents in ports collection
      final allPorts = await _firestore.collection(_portsCollection).get();
      print('All ports in collection:');
      for (var doc in allPorts.docs) {
        print('- Doc ID: ${doc.id}, Data: ${doc.data()}');
      }
    } catch (e) {
      print('Firestore connection error: $e');
    }
  }
}
