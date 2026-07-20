import 'package:cloud_firestore/cloud_firestore.dart';

// ==================== ENUMS & EXTENSIONS ====================

enum UserRole { driver, conductor, secretary, auditTeller, owner }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.driver:
        return 'Driver';
      case UserRole.conductor:
        return 'Conductor';
      case UserRole.secretary:
        return 'Secretary';
      case UserRole.auditTeller:
        return 'Audit Teller';
      case UserRole.owner:
        return 'Owner';
    }
  }
}

enum UserStatus { active, inactive }

extension UserStatusX on UserStatus {
  String get label => this == UserStatus.active ? 'Active' : 'Inactive';
}

enum BusStatus { active, maintenance, inactive }

extension BusStatusX on BusStatus {
  String get label {
    switch (this) {
      case BusStatus.active:
        return 'Active';
      case BusStatus.maintenance:
        return 'Maintenance';
      case BusStatus.inactive:
        return 'Inactive';
    }
  }
}

enum RemittanceStatus { pending, approved, rejected }

extension RemittanceStatusX on RemittanceStatus {
  String get label {
    switch (this) {
      case RemittanceStatus.pending:
        return 'Pending';
      case RemittanceStatus.approved:
        return 'Approved';
      case RemittanceStatus.rejected:
        return 'Rejected';
    }
  }
}

// ==================== APP USER MODEL ====================
class AppUser {
  String id;
  String employeeId;
  String name;
  String username;
  String password;
  UserRole role;
  UserStatus status;

  AppUser({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.username,
    required this.password,
    required this.role,
    required this.status,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String documentId) {
    return AppUser(
      id: documentId,
      employeeId: data['employeeId'] ?? '',
      name: data['name'] ?? '',
      username: data['username'] ?? '',
      password: data['password'] ?? '',
      role: UserRole.values.byName(data['role'] ?? 'driver'),
      status: UserStatus.values.byName(data['status'] ?? 'active'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'name': name,
      'username': username,
      'password': password,
      'role': role.name,
      'status': status.name,
    };
  }
}

// ==================== BUS MODEL ====================
class Bus {
  String id;
  String busNo;
  String plateNumber;
  int capacity;
  String assignedDriverId;
  String assignedDriverName;
  String assignedConductorId;
  String assignedConductorName;
  String defaultRoute;
  BusStatus status;

  Bus({
    required this.id,
    required this.busNo,
    required this.plateNumber,
    required this.capacity,
    required this.assignedDriverId,
    required this.assignedDriverName,
    required this.assignedConductorId,
    required this.assignedConductorName,
    required this.defaultRoute,
    required this.status,
  });

  factory Bus.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Bus(
      id: documentId,
      busNo: data['busNo'] ?? '',
      plateNumber: data['plateNumber'] ?? '',
      capacity: data['capacity'] ?? 0,
      assignedDriverId: data['assignedDriverId'] ?? '',
      assignedDriverName: data['assignedDriverName'] ?? data['assignedDriver'] ?? '',
      assignedConductorId: data['assignedConductorId'] ?? '',
      assignedConductorName: data['assignedConductorName'] ?? data['assignedConductor'] ?? '',
      defaultRoute: data['defaultRoute'] ?? '',
      status: BusStatus.values.byName(data['status'] ?? 'active'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'busNo': busNo,
      'plateNumber': plateNumber,
      'capacity': capacity,
      'assignedDriverId': assignedDriverId,
      'assignedDriverName': assignedDriverName,
      'assignedConductorId': assignedConductorId,
      'assignedConductorName': assignedConductorName,
      'defaultRoute': defaultRoute,
      'status': status.name,
      'busId': id,
    };
  }
}

// ==================== BUS ROUTE MODEL ====================
class BusRoute {
  String id;
  String origin;
  String destination;
  double distanceKm;

  BusRoute({
    required this.id,
    required this.origin,
    required this.destination,
    required this.distanceKm,
  });

  String get label => '$origin \u2192 $destination';

  factory BusRoute.fromFirestore(Map<String, dynamic> data, String documentId) {
    return BusRoute(
      id: documentId,
      origin: data['origin'] ?? '',
      destination: data['destination'] ?? '',
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'origin': origin,
      'destination': destination,
      'distanceKm': distanceKm,
      'routeId': id,
    };
  }
}

// ==================== REMITTANCE TRIP MODEL ====================
class RemittanceTrip {
  int tripNo;
  String route;
  String departure;
  String ticketsRange;
  double grandTotal;

  RemittanceTrip({
    required this.tripNo,
    required this.route,
    required this.departure,
    required this.ticketsRange,
    required this.grandTotal,
  });

  factory RemittanceTrip.fromMap(Map<String, dynamic> map) {
    return RemittanceTrip(
      tripNo: map['tripNo'] ?? 0,
      route: map['route'] ?? '',
      departure: map['departure'] ?? '',
      ticketsRange: map['ticketsRange'] ?? '',
      grandTotal: (map['grandTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tripNo': tripNo,
      'route': route,
      'departure': departure,
      'ticketsRange': ticketsRange,
      'grandTotal': grandTotal,
    };
  }
}

// ==================== REMITTANCE MODEL ====================
class Remittance {
  String id;
  DateTime date;
  String conductor;
  String driver;
  String bus;
  double grossIncome;
  Map<String, double> expenses;
  double driverCommission;
  double conductorCommission;
  double cashDeposit;
  RemittanceStatus status;
  DateTime submitted;
  List<RemittanceTrip> tripDetails;

  Remittance({
    required this.id,
    required this.date,
    required this.conductor,
    required this.driver,
    required this.bus,
    required this.grossIncome,
    required this.expenses,
    required this.driverCommission,
    required this.conductorCommission,
    required this.cashDeposit,
    required this.status,
    required this.submitted,
    required this.tripDetails,
  });

  int get trips => tripDetails.length;
  double get totalExpenses => expenses.values.fold(0.0, (a, b) => a + b);
  double get netGross => grossIncome - totalExpenses;

  // --- Financial Getters ---
  double get bonus => expenses['Bonus'] ?? 0.0;
  double get diesel => expenses['Diesel / Fuel'] ?? 0.0;
  double get tollFee => expenses['Toll Fees'] ?? 0.0;

  double get netCollection =>
      netGross - driverCommission - conductorCommission - cashDeposit;

  double get totalLess =>
      driverCommission +
      conductorCommission +
      bonus +
      diesel +
      tollFee +
      cashDeposit;

  double get totalRevenue => cashDeposit + (grossIncome - totalLess);

  factory Remittance.fromFirestore(Map<String, dynamic> data, String documentId) {
    final rawExpenses = data['expenses'] as Map<String, dynamic>? ?? {};
    final mappedExpenses = rawExpenses.map((key, value) => MapEntry(key, (value as num).toDouble()));

    final rawTrips = data['tripDetails'] as List<dynamic>? ?? [];
    final mappedTrips = rawTrips.map((t) => RemittanceTrip.fromMap(Map<String, dynamic>.from(t))).toList();

    return Remittance(
      id: documentId,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      conductor: data['assignedConductorName'] ?? 'Unknown',
      driver: data['assignedDriverName'] ?? 'Unknown',
      bus: data['busNo'] ?? 'Unknown',
      grossIncome: (data['grossIncome'] as num?)?.toDouble() ?? 0.0,
      expenses: mappedExpenses,
      driverCommission: (data['driverCommission'] as num?)?.toDouble() ?? 0.0,
      conductorCommission: (data['conductorCommission'] as num?)?.toDouble() ?? 0.0,
      cashDeposit: (data['cashDeposit'] as num?)?.toDouble() ?? 0.0,
      status: RemittanceStatus.values.byName(data['status'] ?? 'pending'),
      submitted: (data['submitted'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tripDetails: mappedTrips,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'assignedConductorName': conductor,
      'assignedDriverName': driver,
      'busNo': bus,
      'grossIncome': grossIncome,
      'expenses': expenses,
      'driverCommission': driverCommission,
      'conductorCommission': conductorCommission,
      'cashDeposit': cashDeposit,
      'status': status.name,
      'submitted': Timestamp.fromDate(submitted),
      'tripDetails': tripDetails.map((t) => t.toMap()).toList(),
    };
  }
}

// ==================== FARE SETTINGS MODEL ====================
class FareSettings {
  double minimumFare;
  double baseDistanceKm;
  double ratePerKm;
  Map<String, double> categoryRates; 
  DateTime effectiveDate;

  FareSettings({
    required this.minimumFare,
    required this.baseDistanceKm,
    required this.ratePerKm,
    required this.categoryRates,
    required this.effectiveDate,
  });

  double fareFor(String category, double distanceKm) {
    double baseFare = minimumFare;
    if (distanceKm > baseDistanceKm) {
      baseFare = minimumFare + (distanceKm - baseDistanceKm) * ratePerKm;
    }
    final pct = (categoryRates[category] ?? 100) / 100.0;
    return baseFare * pct;
  }

  factory FareSettings.fromFirestore(Map<String, dynamic> data) {
    final rawRates = data['categoryRates'] as Map<String, dynamic>? ?? {};
    final mappedRates = rawRates.map((key, value) => MapEntry(key, (value as num).toDouble()));

    return FareSettings(
      minimumFare: (data['minimumFare'] as num?)?.toDouble() ?? 0.0,
      baseDistanceKm: (data['baseDistanceKm'] as num?)?.toDouble() ?? 0.0,
      ratePerKm: (data['ratePerKm'] as num?)?.toDouble() ?? 0.0,
      categoryRates: mappedRates,
      effectiveDate: (data['effectiveDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'minimumFare': minimumFare,
      'baseDistanceKm': baseDistanceKm,
      'ratePerKm': ratePerKm,
      'categoryRates': categoryRates,
      'effectiveDate': Timestamp.fromDate(effectiveDate),
    };
  }
}

String _formatTimeOfDay(DateTime dt) {
  final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour >= 12 ? 'PM' : 'AM';
  return '$hour12:$minute $period';
}

DateTime _combineDateAndTime(DateTime datePart, String timeText) {
  final trimmed = timeText.trim();
  final spaceIdx = trimmed.lastIndexOf(' ');
  if (spaceIdx == -1) {
    return DateTime(datePart.year, datePart.month, datePart.day);
  }
  final timePart = trimmed.substring(0, spaceIdx);
  final period = trimmed.substring(spaceIdx + 1).toUpperCase();
  final hm = timePart.split(':');
  int hour = int.tryParse(hm[0]) ?? 0;
  final minute = hm.length > 1 ? (int.tryParse(hm[1]) ?? 0) : 0;
  if (period == 'PM' && hour != 12) hour += 12;
  if (period == 'AM' && hour == 12) hour = 0;
  return DateTime(datePart.year, datePart.month, datePart.day, hour, minute);
}

// ==================== SCHEDULE TRIP MODEL ====================
class ScheduleTrip {
  String id;
  DateTime date;
  String bus;
  String route;
  String driverId;
  String driver;
  String conductorId;
  String conductor;
  String departureTime;
  String status;

  ScheduleTrip({
    required this.id,
    required this.date,
    required this.bus,
    required this.route,
    required this.driverId,
    required this.driver,
    required this.conductorId,
    required this.conductor,
    required this.departureTime,
    this.status = 'scheduled',
  });

  factory ScheduleTrip.fromFirestore(Map<String, dynamic> data, String documentId) {
    final dateField = data['date'];
    final legacyField = data['departureTime'];

    DateTime tripDate;
    if (dateField is Timestamp) {
      tripDate = dateField.toDate();
    } else if (legacyField is Timestamp) {
      tripDate = legacyField.toDate();
    } else {
      tripDate = DateTime.now();
    }

    String depTime;
    if (legacyField is String) {
      depTime = legacyField;
    } else if (legacyField is Timestamp) {
      depTime = _formatTimeOfDay(legacyField.toDate());
    } else {
      depTime = '';
    }

    return ScheduleTrip(
      id: documentId,
      date: tripDate,
      bus: data['busNo'] ?? '',
      route: data['route'] ?? '',
      driverId: data['assignedDriverId'] ?? '',
      driver: data['assignedDriverName'] ?? '',
      conductorId: data['assignedConductorId'] ?? '',
      conductor: data['assignedConductorName'] ?? '',
      departureTime: depTime,
      status: data['status'] ?? 'scheduled',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'departureTime': Timestamp.fromDate(_combineDateAndTime(date, departureTime)),
      'busNo': bus,
      'route': route,
      'assignedDriverId': driverId,
      'assignedDriverName': driver,
      'assignedConductorId': conductorId,
      'assignedConductorName': conductor,
      'status': status,
      'scheduleId': id,
    };
  }
}