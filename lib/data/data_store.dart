// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class DataStore extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Real-time memory lists
  List<AppUser> users = [];
  List<Bus> buses = [];
  List<BusRoute> routes = [];
  List<Remittance> remittances = [];
  List<ScheduleTrip> schedules = [];

  // Default fallback fare settings so your dashboard doesn't crash on initial load
  FareSettings fareSettings = FareSettings(
    minimumFare: 15.00,
    baseDistanceKm: 5.00,
    ratePerKm: 2.49,
    categoryRates: {
      'Regular': 100,
      'Student': 80,
      'Senior Citizen': 80,
      'PWD': 80,
      'Discounted': 80,
    },
    effectiveDate: DateTime(2026, 7, 6),
  );

  DataStore() {
    _initRealtimeListeners();
  }

  // 🔄 Set up real-time stream listeners to Firestore using your NEW collections
  void _initRealtimeListeners() {
    // 1. Listen to Employees (formerly 'users')
    _db.collection('employee_details').snapshots().listen((snapshot) {
      users = snapshot.docs.map((doc) => AppUser.fromFirestore(doc.data(), doc.id)).toList();
      notifyListeners();
    });

    // 2. Listen to Buses (formerly 'buses')
    _db.collection('bus_info').snapshots().listen((snapshot) {
      buses = snapshot.docs.map((doc) => Bus.fromFirestore(doc.data(), doc.id)).toList();
      notifyListeners();
    });

    // 3. Listen to Routes (formerly 'routes')
    _db.collection('route_info').snapshots().listen((snapshot) {
      routes = snapshot.docs.map((doc) => BusRoute.fromFirestore(doc.data(), doc.id)).toList();
      notifyListeners();
    });

    // 4. Listen to Remittances (formerly 'remittances')
    _db.collection('remittance_records').snapshots().listen((snapshot) {
      remittances = snapshot.docs.map((doc) => Remittance.fromFirestore(doc.data(), doc.id)).toList();
      notifyListeners();
    });

    // 5. Listen to Schedules (formerly 'schedules')
    _db.collection('schedule_records').snapshots().listen((snapshot) {
      schedules = snapshot.docs.map((doc) => ScheduleTrip.fromFirestore(doc.data(), doc.id)).toList();
      notifyListeners();
    });

    // 6. Listen to Fare Settings (Single Document inside settings collection)
    _db.collection('settings').doc('fares').snapshots().listen((doc) {
      if (doc.exists && doc.data() != null) {
        fareSettings = FareSettings.fromFirestore(doc.data()!);
        notifyListeners();
      }
    });
  }

  // ==================== 🔥 FIRESTORE CRUD OPERATIONS ====================

  // ---- EMPLOYEES CRUD ----
  Future<void> addUser(AppUser u) async {
    // Generate the next sequential EMP-001, EMP-002, ... ID instead of
    // letting Firestore assign a random auto-ID.
    final snapshot = await _db.collection('employee_details').get();
    int maxNum = 0;
    final idPattern = RegExp(r'^EMP-(\d+)$');
    for (final doc in snapshot.docs) {
      final match = idPattern.firstMatch(doc.id);
      if (match != null) {
        final n = int.tryParse(match.group(1)!) ?? 0;
        if (n > maxNum) maxNum = n;
      }
    }
    final newId = 'EMP-${(maxNum + 1).toString().padLeft(3, '0')}';

    // Stamp the generated ID onto the model's employeeId field too —
    // otherwise the Firestore *document ID* becomes "EMP-050", but the
    // `employeeId` field stored inside that document (what fromFirestore
    // actually reads back into the app) stays empty, since there's no
    // longer a text field feeding it from the Add User form.
    u.employeeId = newId;

    await _db.collection('employee_details').doc(newId).set(u.toFirestore());
  }

  Future<void> updateUser(AppUser u) async {
    await _db.collection('employee_details').doc(u.id).update(u.toFirestore());
  }

  Future<void> deleteUser(String id) async {
    await _db.collection('employee_details').doc(id).delete();
  }

  // ---- BUSES CRUD ----
  Future<void> addBus(Bus b) async {
    // Uses the busNo as the document ID (e.g. BUS-01)
    final String docId = 'BUS-${b.busNo.padLeft(2, '0')}';
    b.id = docId; // so toFirestore()'s busId field matches the doc ID
    await _db.collection('bus_info').doc(docId).set(b.toFirestore());
  }

  Future<void> updateBus(Bus b) async {
    await _db.collection('bus_info').doc(b.id).update(b.toFirestore());
  }

  Future<void> deleteBus(String id) async {
    await _db.collection('bus_info').doc(id).delete();
  }

  // ---- ROUTES CRUD ----
  Future<void> addRoute(BusRoute r) async {
    // Uses origin-destination initials as the document ID to keep it clean
    final String routeId = 'RTE-${r.origin.substring(0, 3).toUpperCase()}-${r.destination.substring(0, 3).toUpperCase()}';
    r.id = routeId; // so toFirestore()'s routeId field matches the doc ID
    await _db.collection('route_info').doc(routeId).set(r.toFirestore());
  }

  Future<void> updateRoute(BusRoute r) async {
    await _db.collection('route_info').doc(r.id).update(r.toFirestore());
  }

  Future<void> deleteRoute(String id) async {
    await _db.collection('route_info').doc(id).delete();
  }

  // ---- SCHEDULES CRUD ----
  Future<void> addSchedule(ScheduleTrip s) async {
    // Generate the next sequential SCH-001, SCH-002, ... ID instead of
    // letting Firestore assign a random auto-ID.
    final snapshot = await _db.collection('schedule_records').get();
    int maxNum = 0;
    final idPattern = RegExp(r'^SCH-(\d+)$');
    for (final doc in snapshot.docs) {
      final match = idPattern.firstMatch(doc.id);
      if (match != null) {
        final n = int.tryParse(match.group(1)!) ?? 0;
        if (n > maxNum) maxNum = n;
      }
    }
    final newId = 'SCH-${(maxNum + 1).toString().padLeft(3, '0')}';
    s.id = newId; // so toFirestore()'s scheduleId field matches the doc ID
    await _db.collection('schedule_records').doc(newId).set(s.toFirestore());
  }

  Future<void> updateSchedule(ScheduleTrip s) async {
    await _db.collection('schedule_records').doc(s.id).update(s.toFirestore());
  }

  Future<void> deleteSchedule(String id) async {
    await _db.collection('schedule_records').doc(id).delete();
  }

  // ---- REMITTANCE STATUS UPDATE ----
  Future<void> setRemittanceStatus(String id, RemittanceStatus status) async {
    await _db.collection('remittance_records').doc(id).update({'status': status.name});
  }

  // ---- FARE SETTINGS ----
  Future<void> updateFareSettings(FareSettings f) async {
    await _db.collection('settings').doc('fares').set(f.toFirestore());
  }

  // ==================== 🧹 ONE-TIME LEGACY DATA MIGRATION ====================
  // Rewrites every existing document in bus_info, schedule_records, and
  // route_info through fromFirestore() -> toFirestore(), using set()
  // (full overwrite, not merge). This drops legacy-only fields
  // (busId, assignedDriverId, assignedConductorId, the old *Name-only
  // shape, etc.) and brings every document to the exact same shape that
  // the current Add/Edit forms write.
  //
  // Run this ONCE (e.g. from a temporary debug button), confirm the
  // Firestore console looks consistent, then remove the button/call so
  // it doesn't run again on every app load.
  Future<void> migrateLegacyData() async {
    final busSnap = await _db.collection('bus_info').get();
    final busBatch = _db.batch();
    for (final doc in busSnap.docs) {
      final bus = Bus.fromFirestore(doc.data(), doc.id);
      busBatch.set(doc.reference, bus.toFirestore());
    }
    await busBatch.commit();
    print('Migrated ${busSnap.docs.length} bus_info documents.');

    final schedSnap = await _db.collection('schedule_records').get();
    final schedBatch = _db.batch();
    for (final doc in schedSnap.docs) {
      final trip = ScheduleTrip.fromFirestore(doc.data(), doc.id);
      schedBatch.set(doc.reference, trip.toFirestore());
    }
    await schedBatch.commit();
    print('Migrated ${schedSnap.docs.length} schedule_records documents.');

    final routeSnap = await _db.collection('route_info').get();
    final routeBatch = _db.batch();
    for (final doc in routeSnap.docs) {
      final route = BusRoute.fromFirestore(doc.data(), doc.id);
      routeBatch.set(doc.reference, route.toFirestore());
    }
    await routeBatch.commit();
    print('Migrated ${routeSnap.docs.length} route_info documents.');

    print('Legacy data migration complete.');
  }

  // ---- DASHBOARD DERIVED STATS ----
  // Computes cumulative "Total Revenue" across all approved remittances for the current monthly dataset
  double get totalRevenueMonth => remittances.fold(0.0, (currentTotal, r) {
      if (r.status != RemittanceStatus.approved) return currentTotal;

      // Dynamic fallback formula: Cash Deposit + Net Collection
      final diesel = r.expenses['Diesel / Fuel'] ?? 0.0;
      final toll = r.expenses['Toll Fees'] ?? 1000.0;
      final bonus = r.expenses['Bonus'] ?? 500.0;

      final totalLess = r.driverCommission + r.conductorCommission + bonus + diesel + r.cashDeposit + toll;
      final netCollection = r.grossIncome - totalLess;

      final totalRevenue = r.cashDeposit + netCollection;

      return currentTotal + totalRevenue;
    });

  int get passengersMonth {
    return remittances.where((r) => r.status == RemittanceStatus.approved).fold(0, (total, r) {
      // Sums the passengers from all trips within each remittance
      int tripPassengers = r.tripDetails.fold(0, (tSum, trip) {
        final rangeParts = trip.ticketsRange.split('-');
        if (rangeParts.length == 2) {
          final start = int.tryParse(rangeParts[0].trim()) ?? 0;
          final end = int.tryParse(rangeParts[1].trim()) ?? 0;
          return tSum + (end - start);
        }
        return tSum;
      });
      return total + tripPassengers;
    });
  }
}

class DataScope extends InheritedNotifier<DataStore> {
  const DataScope({super.key, required DataStore store, required super.child}) : super(notifier: store);

  static DataStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DataScope>();
    assert(scope != null, 'DataScope not found in context');
    return scope!.notifier!;
  }
}