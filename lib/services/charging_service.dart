import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/dashboard_charging_widget.dart';

// Service class to handle package selection and charging initiation
class ChargingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  static Future<Map<String, String>?> selectPackageAndStartCharging({
    required String packageName,
    required String portType,
    required GlobalKey<DashboardChargingWidgetState> chargingWidgetKey,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Reserve a charging port
      final portId = await _reserveChargingPort(portType, user.uid, packageName);
      if (portId == null) {
        throw Exception('No available charging ports');
      }

      // Create order in Realtime Database
      final orderId = DateTime.now().millisecondsSinceEpoch.toString();
      final dbRef = _database.ref().child('orders/${user.uid}/$orderId');
      
      await dbRef.set({
        'id': orderId,
        'packageName': packageName,
        'portType': portType,
        'portId': portId,
        'status': 'Active',
        'startTime': DateTime.now().toIso8601String(),
        'durationMinutes': 1, // Development: 1 minute
      });

      // Create order in Firestore
      final firestoreDoc = await _firestore.collection('orders').add({
        'userId': user.uid,
        'orderId': orderId,
        'packageName': packageName,
        'portType': portType,
        'portId': portId,
        'status': 'Active',
        'startTime': Timestamp.now(),
        'durationMinutes': 1, // Development: 1 minute
        'createdAt': Timestamp.now(),
      });

      // Start charging countdown
      chargingWidgetKey.currentState?.startCharging(
        orderId: orderId,
        firestoreId: firestoreDoc.id,
        packageName: packageName,
        portId: portId,
        durationMinutes: 1, // Development: 1 minute
      );

      return {
        'orderId': orderId,
        'firestoreId': firestoreDoc.id,
        'portId': portId,
      };
    } catch (e) {
      print('Error starting charging: $e');
      return null;
    }
  }

  static Future<String?> _reserveChargingPort(String portType, String userId, String packageName) async {
    try {
      // Find available port
      final snapshot = await _firestore
          .collection('charging_ports')
          .where('type', isEqualTo: portType)
          .where('isAvailable', isEqualTo: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;

      final availablePort = snapshot.docs.first;
      
      // Reserve the port
      await _firestore.collection('charging_ports').doc(availablePort.id).update({
        'isAvailable': false,
        'currentUserId': userId,
        'currentPackage': packageName,
        'sessionStartTime': Timestamp.now(),
      });

      // Create charging session record
      await _firestore.collection('charging_sessions').add({
        'portId': availablePort.id,
        'portType': portType,
        'userId': userId,
        'packageName': packageName,
        'startTime': Timestamp.now(),
        'endTime': null,
        'status': 'active',
        'isCompleted': false,
      });

      return availablePort.id;
    } catch (e) {
      print('Error reserving port: $e');
      return null;
    }
  }

  static Future<Map<String, String>?> createOrderAndStartCharging({
    required String userId,
    required Map<String, dynamic> package,
    required String portId,
    required String portType,
    required GlobalKey<DashboardChargingWidgetState>? chargingWidgetKey,
  }) async {
    try {
      // 1. Create order in Realtime Database
      final dbRef = FirebaseDatabase.instance.ref().child('orders').push();
      final orderId = dbRef.key!;
      final duration = 1; // Always 1 minute for development
      final orderData = {
        'userId': userId,
        'package': package['name'],
        'price': package['price'],
        'duration': duration,
        'portId': portId,
        'portType': portType,
        'status': 'Charging Started',
        'timestamp': DateTime.now().toIso8601String(),
      };
      await dbRef.set(orderData);

      // 2. Create order in Firestore (to get docId for later update)
      final docRef = await FirebaseFirestore.instance.collection('orders').add({
        ...orderData,
        'status': 'Charging Started',
        'timestamp': Timestamp.now(),
      });

      // 3. Start countdown on dashboard
      chargingWidgetKey?.currentState?.startCharging(
        orderId: orderId,
        firestoreId: docRef.id,
        packageName: package['name'],
        portId: portId,
        durationMinutes: duration, // Always 1 minute
      );

      return {'orderId': orderId, 'firestoreId': docRef.id};
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }
}