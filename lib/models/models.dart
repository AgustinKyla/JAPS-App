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
      // Older docs only ever stored the plain name under "assignedDriver" -
      // keep that as a fallback so those records still display correctly.
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
      // Some bus_info docs already had a busId field mirroring the document
      // ID - write it going forward so every doc has it, matching the
      // routeId / scheduleId pattern used elsewhere.
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
      // Some route_info docs already had a routeId field mirroring the
      // document ID - write it going forward so every doc has it.
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

  // --- New Financial Getters ---
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
  Map<String, double> categoryRates; // percent 0-100
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

// Formats the time-of-day portion of a DateTime as "h:mm AM/PM", matching
// the format produced by the time picker in the Schedules form.
String _formatTimeOfDay(DateTime dt) {
  final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour >= 12 ? 'PM' : 'AM';
  return '$hour12:$minute $period';
}

// Parses a "h:mm AM/PM" string (as produced by the time picker) and
// combines it with a calendar date into a single DateTime - the inverse of
// _formatTimeOfDay, used so departureTime can be stored as one Timestamp.
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
      // Old records stored the date (with a meaningless time-of-day) under
      // the 'departureTime' key. Recover the calendar date from it.
      tripDate = legacyField.toDate();
    } else {
      tripDate = DateTime.now();
    }

    String depTime;
    if (legacyField is String) {
      // New-format record: departureTime is the actual "h:mm AM/PM" text.
      depTime = legacyField;
    } else if (legacyField is Timestamp) {
      // Old-format record: departureTime is a Timestamp whose time-of-day
      // component IS the real departure time - format it instead of
      // discarding it.
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
      // Stored as ONE Timestamp combining the date and time-of-day, matching
      // the convention already used by the existing schedule_records docs -
      // no separate 'date' field, so every doc has the same shape.
      'departureTime': Timestamp.fromDate(_combineDateAndTime(date, departureTime)),
      'busNo': bus,
      'route': route,
      'assignedDriverId': driverId,
      'assignedDriverName': driver,
      'assignedConductorId': conductorId,
      'assignedConductorName': conductor,
      'status': status,
      // Some schedule_records docs already had a scheduleId field mirroring
      // the document ID - write it going forward so every doc has it.
      'scheduleId': id,
    };
  }
}