import 'package:flutter/foundation.dart';

// PASSENGER STATUS ENUM

enum SeatTypeStatus {
  sold(1),
  tripMigrated(2),
  openTicket(3);

  final int value;
  const SeatTypeStatus(this.value);

  static SeatTypeStatus fromInt(int value) {
    return SeatTypeStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SeatTypeStatus.sold,
    );
  }
}

// PERMISSION CONSTANTS

class AppPermissions {
  static const String verifyBoarding = 'TICKET_VALIDATOR_VERIFY_BOARDING';
  static const String tripManagement = 'TICKET_VALIDATOR_TRIP_MANAGEMENT';
  static const String approval = 'TICKET_VALIDATOR_APPROVAL';
  static const String reconcile = 'TICKET_VALIDATOR_RECONCILE';

  static const List<String> all = [
    verifyBoarding,
    tripManagement,
    approval,
    reconcile,
  ];
}

// CITY Detailss here

class CitySummary {
  final int? id;
  final String? code;
  final String? name;

  CitySummary({this.id, this.code, this.name});

  factory CitySummary.fromJson(Map<String, dynamic> json) {
    return CitySummary(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      code: json['code']?.toString(),
      name: json['name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
  };

  CitySummary copyWith({int? id, String? code, String? name}) {
    return CitySummary(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CitySummary &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ code.hashCode ^ name.hashCode;

  @override
  String toString() => 'CitySummary(id: $id, code: $code, name: $name)';
}

// ==========================================================
// ROUTE SUMMARY
// ==========================================================
class RouteSummary {
  final int? id;
  final String? code;
  final String? name;

  RouteSummary({this.id, this.code, this.name});

  factory RouteSummary.fromJson(Map<String, dynamic> json) {
    return RouteSummary(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      code: json['code']?.toString(),
      name: json['name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
  };

  RouteSummary copyWith({int? id, String? code, String? name}) {
    return RouteSummary(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteSummary &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ code.hashCode ^ name.hashCode;

  @override
  String toString() => 'RouteSummary(id: $id, code: $code, name: $name)';
}

// ==========================================================
// VEHICLE DETAILS
// ==========================================================
class VehicleDetails {
  final int? id;
  final String? registrationNo;
  final String? vehicleNo;
  final String? manufacturer;

  VehicleDetails({this.id, this.registrationNo, this.vehicleNo, this.manufacturer});

  factory VehicleDetails.fromJson(Map<String, dynamic> json) {
    return VehicleDetails(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      registrationNo: json['registrationNo']?.toString() ?? json['regNo']?.toString(),
      vehicleNo: json['vehicleNo']?.toString(),
      manufacturer: json['manufacturer']?.toString() ?? json['make']?.toString() ?? json['type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'registrationNo': registrationNo,
    'vehicleNo': vehicleNo,
    'manufacturer': manufacturer,
  };

  VehicleDetails copyWith({int? id, String? registrationNo, String? vehicleNo, String? manufacturer}) {
    return VehicleDetails(
      id: id ?? this.id,
      registrationNo: registrationNo ?? this.registrationNo,
      vehicleNo: vehicleNo ?? this.vehicleNo,
      manufacturer: manufacturer ?? this.manufacturer,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleDetails &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          registrationNo == other.registrationNo &&
          vehicleNo == other.vehicleNo &&
          manufacturer == other.manufacturer;

  @override
  int get hashCode => Object.hash(id, registrationNo, vehicleNo, manufacturer);

  @override
  String toString() => 'VehicleDetails(id: $id, reg: $registrationNo, no: $vehicleNo, mfr: $manufacturer)';
}


// Staff info's
class StaffDetails {
  final int? id;
  final String? displayName;
  final String? mobile;
  final String? erpId;

  StaffDetails({this.id, this.displayName, this.mobile, this.erpId});

  factory StaffDetails.fromJson(Map<String, dynamic> json) {
    // Advanced lookup for ID to ensure E10-114261 style IDs are never missed
    // This priority list covers almost all backend naming conventions
    final rawErpId = json['erpId']?.toString() ?? 
                     json['staff_no']?.toString() ?? 
                     json['staffNo']?.toString() ?? 
                     json['employee_no']?.toString() ?? 
                     json['employeeNo']?.toString() ?? 
                     json['staff_id']?.toString() ?? 
                     json['staffId']?.toString() ?? 
                     json['employeeId']?.toString() ?? 
                     json['empId']?.toString() ?? 
                     json['staff_code']?.toString() ??
                     json['code']?.toString() ?? 
                     json['userId']?.toString();

    return StaffDetails(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      displayName: json['displayName']?.toString() ?? json['name']?.toString() ?? 'Unknown Staff',
      mobile: json['mobile']?.toString() ?? json['phone']?.toString(),
      erpId: rawErpId, // Removed the fallback to short DB id
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'mobile': mobile,
    'erpId': erpId,
  };

  StaffDetails copyWith({int? id, String? displayName, String? mobile, String? erpId}) {
    return StaffDetails(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      mobile: mobile ?? this.mobile,
      erpId: erpId ?? this.erpId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffDetails &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          displayName == other.displayName &&
          mobile == other.mobile &&
          erpId == other.erpId;

  @override
  int get hashCode => Object.hash(id, displayName, mobile, erpId);

  @override
  String toString() => 'StaffDetails(id: $id, name: $displayName, erpId: $erpId)';
}


// Trip (Trip Summary)

class Trip {
  // Official Documented Fields
  final String id;
  final String? coachCode;
  final String? tripDate;
  final DateTime? departureTime;
  final String? status;

  // Documented Nested Objects
  final CitySummary? origin;
  final CitySummary? destination;
  final RouteSummary? route;
  final VehicleDetails? vehicle;
  final StaffDetails? driver;
  final StaffDetails? helper;
  final StaffDetails? supervisor;

  // Application State
  final String operationType;
  final DateTime reportingTime;
  final List<Ticket> tickets;

  Trip({
    required this.id,
    this.coachCode,
    this.tripDate,
    this.departureTime,
    this.status,
    this.origin,
    this.destination,
    this.route,
    this.vehicle,
    this.driver,
    this.helper,
    this.supervisor,
    this.operationType = 'Boarding',
    DateTime? reportingTime,
    this.tickets = const [],
  }) : reportingTime = reportingTime ?? (departureTime?.subtract(const Duration(minutes: 30)) ?? DateTime.now());

  String get fromStation => origin?.name ?? '';
  String get fromCode => origin?.code ?? '';
  String get toStation => destination?.name ?? '';
  String get toCode => destination?.code ?? '';
  String get busStation => origin?.name ?? '';
  String? get vehicleNo => vehicle?.vehicleNo ?? vehicle?.registrationNo;
  String? get driverName => driver?.displayName;
  String? get helperName => helper?.displayName;
  String? get supervisorName => supervisor?.displayName;
  
  // ERP ID
  String? get driverErpId => driver?.erpId;
  String? get helperErpId => helper?.erpId;
  String? get supervisorErpId => supervisor?.erpId;


  factory Trip.fromJson(Map<String, dynamic> json) {
    DateTime? depTime;
    if (json['departureTime'] != null) {
      depTime = DateTime.tryParse(json['departureTime'].toString());
    }

    List<Ticket> ticketsList = [];
    if (json['tickets'] is List) {
      ticketsList = (json['tickets'] as List)
          .map<Ticket>((i) => Ticket.fromJson(i is Map ? i : {}))
          .toList();
    }

    return Trip(
      id: json['id']?.toString() ?? json['tripId']?.toString() ?? '',
      coachCode: json['coachCode']?.toString(),
      tripDate: json['tripDate']?.toString(),
      departureTime: depTime,
      status: json['status']?.toString(),
      origin: json['origin'] is Map ? CitySummary.fromJson(Map<String, dynamic>.from(json['origin'])) : null,
      destination: json['destination'] is Map ? CitySummary.fromJson(Map<String, dynamic>.from(json['destination'])) : null,
      route: json['route'] is Map ? RouteSummary.fromJson(Map<String, dynamic>.from(json['route'])) : null,
      vehicle: json['vehicle'] is Map ? VehicleDetails.fromJson(Map<String, dynamic>.from(json['vehicle'])) : null,
      driver: json['driver'] is Map ? StaffDetails.fromJson(Map<String, dynamic>.from(json['driver'])) : null,
      helper: json['helper'] is Map ? StaffDetails.fromJson(Map<String, dynamic>.from(json['helper'])) : null,
      supervisor: json['supervisor'] is Map ? StaffDetails.fromJson(Map<String, dynamic>.from(json['supervisor'])) : null,
      operationType: json['operationType']?.toString() ?? 'Boarding',
      reportingTime: json['reportingTime'] != null ? DateTime.tryParse(json['reportingTime'].toString()) : null,
      tickets: ticketsList,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'coachCode': coachCode,
    'tripDate': tripDate,
    'departureTime': departureTime?.toIso8601String(),
    'status': status,
    'origin': origin?.toJson(),
    'destination': destination?.toJson(),
    'route': route?.toJson(),
    'vehicle': vehicle?.toJson(),
    'driver': driver?.toJson(),
    'helper': helper?.toJson(),
    'supervisor': supervisor?.toJson(),
    'operationType': operationType,
    'reportingTime': reportingTime.toIso8601String(),
    'tickets': tickets.map((t) => t.toJson()).toList(),
  };

  Trip copyWith({
    String? id,
    String? coachCode,
    String? tripDate,
    DateTime? departureTime,
    String? status,
    CitySummary? origin,
    CitySummary? destination,
    RouteSummary? route,
    VehicleDetails? vehicle,
    StaffDetails? driver,
    StaffDetails? helper,
    StaffDetails? supervisor,
    String? operationType,
    DateTime? reportingTime,
    List<Ticket>? tickets,
  }) {
    return Trip(
      id: id ?? this.id,
      coachCode: coachCode ?? this.coachCode,
      tripDate: tripDate ?? this.tripDate,
      departureTime: departureTime ?? this.departureTime,
      status: status ?? this.status,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      route: route ?? this.route,
      vehicle: vehicle ?? this.vehicle,
      driver: driver ?? this.driver,
      helper: helper ?? this.helper,
      supervisor: supervisor ?? this.supervisor,
      operationType: operationType ?? this.operationType,
      reportingTime: reportingTime ?? this.reportingTime,
      tickets: tickets ?? this.tickets,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Trip &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          coachCode == other.coachCode &&
          tripDate == other.tripDate &&
          departureTime == other.departureTime &&
          status == other.status &&
          origin == other.origin &&
          destination == other.destination &&
          route == other.route &&
          vehicle == other.vehicle &&
          driver == other.driver &&
          helper == other.helper &&
          supervisor == other.supervisor &&
          operationType == other.operationType &&
          listEquals(tickets, other.tickets);

  @override
  int get hashCode => Object.hash(id, coachCode, tripDate, departureTime, status, origin, destination, route, vehicle, driver, helper, supervisor, operationType, tickets);

  @override
  String toString() => 'Trip(id: $id, coach: $coachCode, status: $status, from: ${origin?.name}, to: ${destination?.name})';
}

// USER MODEL
class Permission {
  final String name;
  final String title;

  Permission({required this.name, required this.title});

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      name: (json['name'] ?? json['code'] ?? '').toString(),
      title: (json['title'] ?? json['displayName'] ?? json['name'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'title': title};

  Permission copyWith({String? name, String? title}) =>
      Permission(name: name ?? this.name, title: title ?? this.title);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Permission && runtimeType == other.runtimeType && name == other.name && title == other.title;

  @override
  int get hashCode => name.hashCode ^ title.hashCode;

  @override
  String toString() => 'Permission($name)';
}

class UserRole {
  final int id;
  final String name;
  final String? description;
  final List<Permission> permissions;

  UserRole({
    required this.id,
    required this.name,
    this.description,
    this.permissions = const [],
  });

  factory UserRole.fromJson(Map<String, dynamic> json) {
    final permsRaw = json['permissions'] ?? json['permissions_list'] ?? [];
    List<Permission> parsedPerms = [];
    if (permsRaw is List) {
      parsedPerms = permsRaw
          .map((p) => p is Map ? Permission.fromJson(Map<String, dynamic>.from(p)) : null)
          .whereType<Permission>()
          .toList();
    }

    return UserRole(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      permissions: parsedPerms,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'permissions': permissions.map((p) => p.toJson()).toList(),
  };

  UserRole copyWith({int? id, String? name, String? description, List<Permission>? permissions}) =>
      UserRole(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        permissions: permissions ?? this.permissions,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserRole && runtimeType == other.runtimeType && id == other.id && listEquals(permissions, other.permissions);

  @override
  int get hashCode => Object.hash(id, name, permissions);

  @override
  String toString() => 'UserRole($name, permissions: ${permissions.length})';
}

class User {
  final String id;
  final String username;
  final String fullName;
  final String mobile;
  final String? email;
  final String? role;
  final List<UserRole> roles;
  final String? permission; // The exactly ONE permission from contract
  final int? branchId;
  final String? branchName;
  final String? profilePicUrl;
  final String? erpId;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.mobile,
    this.email,
    this.role,
    this.roles = const [],
    this.permission,
    this.branchId,
    this.branchName,
    this.profilePicUrl,
    this.erpId,
  });

  bool hasPermission(String permissionName) {
    if (permission == permissionName) return true;
    for (var r in roles) {
      if (r.permissions.any((p) => p.name == permissionName)) return true;
    }
    return false;
  }

  // Centralized Permission Policy Getters
  bool get canVerifyBoarding => hasPermission(AppPermissions.verifyBoarding);
  bool get canManageTrip => hasPermission(AppPermissions.tripManagement);
  bool get canApprove => hasPermission(AppPermissions.approval);
  bool get canReconcile => hasPermission(AppPermissions.reconcile);

  factory User.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = (json['user'] is Map)
        ? Map<String, dynamic>.from(json['user'])
        : (json['data'] is Map ? Map<String, dynamic>.from(json['data']) : json);

    final List<UserRole> userRoles = [];
    if (data['roles'] is List) {
      for (var r in data['roles']) {
        if (r is Map) userRoles.add(UserRole.fromJson(Map<String, dynamic>.from(r)));
      }
    }

    // Try to extract the single permission as per contract
    String? contractPermission;
    if (data['permission'] != null) {
      contractPermission = data['permission'].toString();
    } else if (data['permissions'] is List && (data['permissions'] as List).isNotEmpty) {
      contractPermission = (data['permissions'] as List).first.toString();
    } else if (userRoles.isNotEmpty && userRoles.first.permissions.isNotEmpty) {
      contractPermission = userRoles.first.permissions.first.name;
    }

    // Robust ERP ID mapping for User model to ensure "E10-114261" style IDs are captured
    final rawErpId = data['erpId']?.toString() ?? 
                     data['staff_no']?.toString() ?? 
                     data['staffNo']?.toString() ?? 
                     data['employee_no']?.toString() ?? 
                     data['employeeNo']?.toString() ?? 
                     data['staff_id']?.toString() ?? 
                     data['staffId']?.toString() ?? 
                     data['employeeId']?.toString() ?? 
                     data['empId']?.toString() ?? 
                     data['staff_code']?.toString() ??
                     data['code']?.toString() ?? 
                     data['userId']?.toString();

    return User(
      id: data['id']?.toString() ?? data['staffId']?.toString() ?? '',
      username: data['username']?.toString() ?? '',
      fullName: data['displayName']?.toString() ?? data['fullName']?.toString() ?? data['name']?.toString() ?? '',
      mobile: data['mobile']?.toString() ?? '',
      email: data['email']?.toString(),
      role: data['role']?.toString(),
      roles: userRoles,
      permission: contractPermission,
      branchId: data['branchId'] is int ? data['branchId'] : int.tryParse(data['branchId']?.toString() ?? ''),
      branchName: data['branchName']?.toString() ?? (data['branch'] is Map ? data['branch']['name']?.toString() : null) ?? 'DHAKA',
      profilePicUrl: data['profilePicUrl']?.toString() ?? data['photo']?.toString(),
      erpId: rawErpId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'displayName': fullName,
    'mobile': mobile,
    'email': email,
    'role': role,
    'roles': roles.map((r) => r.toJson()).toList(),
    'permission': permission,
    'branchId': branchId,
    'branchName': branchName,
    'profilePicUrl': profilePicUrl,
    'erpId': erpId,
  };

  User mergeWith(User? existing) {
    if (existing == null) return this;
    return copyWith(
      role: (role == null || role!.isEmpty) ? existing.role : role,
      roles: roles.isEmpty ? existing.roles : roles,
      permission: permission ?? existing.permission,
      branchName: (branchName == null || branchName!.isEmpty) ? existing.branchName : branchName,
    );
  }

  User copyWith({
    String? id,
    String? username,
    String? fullName,
    String? mobile,
    String? email,
    String? role,
    List<UserRole>? roles,
    String? permission,
    int? branchId,
    String? branchName,
    String? profilePicUrl,
    String? erpId,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      role: role ?? this.role,
      roles: roles ?? this.roles,
      permission: permission ?? this.permission,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      erpId: erpId ?? this.erpId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id && username == other.username;

  @override
  int get hashCode => id.hashCode ^ username.hashCode;

  @override
  String toString() => 'User(id: $id, name: $fullName, role: $role)';
}

// ==========================================================
// TICKET MODEL
// ==========================================================
class Ticket {
  final String pnr;
  final String seatNo;
  final String passengerName;
  final String? secretCode;
  final String mobile;
  bool isVerified;
  final double? fare;
  final String? status;
  final String? boardingPoint;
  final String? droppingPoint;
  final String? coach;
  final String? source;
  final String? destination;

  Ticket({
    required this.pnr,
    required this.seatNo,
    required this.passengerName,
    this.secretCode,
    this.mobile = '',
    this.isVerified = false,
    this.fare,
    this.status,
    this.boardingPoint,
    this.droppingPoint,
    this.coach,
    this.source,
    this.destination,
  });

  factory Ticket.fromJson(Map json) {
    String? s(dynamic v) {
      if (v == null) return null;
      if (v is List) return v.join(', ');
      return v.toString().trim();
    }

    final data = json['data'] is Map ? json['data'] as Map : null;
    final ticket = json['ticket'] is Map ? json['ticket'] as Map : null;

    dynamic find(String key) => json[key] ?? data?[key] ?? ticket?[key];

    final passenger = (json['passenger'] is Map ? json['passenger'] as Map : null) ??
        (data != null && data['passenger'] is Map ? data['passenger'] as Map : null) ??
        (ticket != null && ticket['passenger'] is Map ? ticket['passenger'] as Map : null);

    final trip = (json['trip'] is Map ? json['trip'] as Map : null) ??
        (data != null && data['trip'] is Map ? data['trip'] as Map : null) ??
        (ticket != null && ticket['trip'] is Map ? ticket['trip'] as Map : null);

    final fareMap = (json['fare'] is Map ? json['fare'] as Map : null) ??
        (data != null && data['fare'] is Map ? data['fare'] as Map : null) ??
        (ticket != null && ticket['fare'] is Map ? ticket['fare'] as Map : null);

    final seatMap = (json['seat'] is Map ? json['seat'] as Map : null) ??
        (data != null && data['seat'] is Map ? data['seat'] as Map : null) ??
        (ticket != null && ticket['seat'] is Map ? ticket['seat'] as Map : null);

    bool isTrue(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is int) return v == 1;
      final val = v.toString().toLowerCase();
      return val == '1' || val == 'true' || val == 'yes' || val == 'verified' || val == 'boarded' || val == 'success';
    }

    bool verified = isTrue(find('isVerified')) ||
        isTrue(find('is_verified')) ||
        isTrue(find('isBoarded')) ||
        isTrue(find('is_boarded')) ||
        isTrue(find('boarded')) ||
        isTrue(find('verified')) ||
        isTrue(find('status')) ||
        isTrue(find('boarding_status'));

    if (!verified && passenger != null) {
      verified = isTrue(passenger['is_verified']) ||
          isTrue(passenger['is_boarded']) ||
          isTrue(passenger['status']) ||
          isTrue(passenger['boarding_status']);
    }

    return Ticket(
      pnr: s(find('pnr')) ?? s(find('PNR')) ?? s(find('ticket_no')) ?? s(find('ticketNo')) ?? '',
      seatNo: s(find('seatNumber')) ??
          s(seatMap?['seatNumber']) ??
          s(find('seatNo')) ??
          s(find('seat_number')) ??
          s(find('seat')) ??
          s(find('seats')) ??
          '',
      passengerName: _parseName(json),
      mobile: s(find('mobile')) ?? s(find('phone')) ?? s(find('passenger_mobile')) ?? s(passenger?['mobile']) ?? s(passenger?['phone']) ?? '',
      secretCode: s(find('secretCode')) ?? s(find('secret_code')) ?? s(find('pin')) ?? s(find('PIN')) ?? s(find('secret_pin')),
      isVerified: verified,
      fare: fareMap != null ? (fareMap['total'] as num?)?.toDouble() : (find('fare') is num ? (find('fare') as num).toDouble() : null),
      status: s(find('status')),
      coach: s(find('coach')) ?? s(trip?['coach']),
      boardingPoint: _parseStation(json, ['boarding', 'boarding_point', 'boardingPoint', 'reporting_station', 'counter_name']),
      droppingPoint: _parseStation(json, ['dropping_point', 'droppingPoint', 'landing_station', 'end_station', 'drop_off']),
      source: _parseStation(json, ['source', 'from_station', 'from', 'origin', 'start_station']),
      destination: _parseStation(json, ['destination', 'to_station', 'to', 'landing_station', 'end_station']),
    );
  }

  Map toJson() {
    return {
      'pnr': pnr,
      'seatNo': seatNo,
      'passengerName': passengerName,
      'secretCode': secretCode,
      'mobile': mobile,
      'isVerified': isVerified,
      'fare': fare,
      'status': status,
      'boardingPoint': boardingPoint,
      'droppingPoint': droppingPoint,
      'coach': coach,
      'source': source,
      'destination': destination,
    };
  }

  Ticket copyWith({
    String? pnr,
    String? seatNo,
    String? passengerName,
    String? secretCode,
    String? mobile,
    bool? isVerified,
    double? fare,
    String? status,
    String? boardingPoint,
    String? droppingPoint,
    String? coach,
    String? source,
    String? destination,
  }) {
    return Ticket(
      pnr: pnr ?? this.pnr,
      seatNo: seatNo ?? this.seatNo,
      passengerName: passengerName ?? this.passengerName,
      secretCode: secretCode ?? this.secretCode,
      mobile: mobile ?? this.mobile,
      isVerified: isVerified ?? this.isVerified,
      fare: fare ?? this.fare,
      status: status ?? this.status,
      boardingPoint: boardingPoint ?? this.boardingPoint,
      droppingPoint: droppingPoint ?? this.droppingPoint,
      coach: coach ?? this.coach,
      source: source ?? this.source,
      destination: destination ?? this.destination,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ticket && runtimeType == other.runtimeType && pnr == other.pnr && seatNo == other.seatNo;

  @override
  int get hashCode => pnr.hashCode ^ seatNo.hashCode;

  @override
  String toString() => 'Ticket(PNR: $pnr, Seat: $seatNo, Name: $passengerName)';

  static int naturalCompare(String a, String b) {
    try {
      final RegExp regExp = RegExp(r'(\d+)|(\D+)');
      final Iterable matchesA = regExp.allMatches(a);
      final Iterable matchesB = regExp.allMatches(b);
      final List partsA = matchesA.map((m) => m.group(0)!).toList();
      final List partsB = matchesB.map((m) => m.group(0)!).toList();
      int length = partsA.length < partsB.length ? partsA.length : partsB.length;
      for (int i = 0; i < length; i++) {
        final String partA = partsA[i];
        final String partB = partsB[i];
        final isDigitA = partA.codeUnitAt(0) >= 48 && partA.codeUnitAt(0) <= 57;
        final isDigitB = partB.codeUnitAt(0) >= 48 && partB.codeUnitAt(0) <= 57;
        if (isDigitA && isDigitB) {
          final int numA = int.parse(partA);
          final int numB = int.parse(partB);
          if (numA != numB) return numA.compareTo(numB);
        } else {
          if (partA != partB) return partA.compareTo(partB);
        }
      }
      return partsA.length.compareTo(partsB.length);
    } catch (e) {
      return a.compareTo(b);
    }
  }

  static String _parseName(Map json) {
    final d = json['data'] is Map ? json['data'] as Map : null;
    final t = json['ticket'] is Map ? json['ticket'] as Map : null;
    final r = json['reservation'] is Map ? json['reservation'] as Map : null;
    final p = json['passenger'] is Map ? json['passenger'] as Map : null;
    final pd = (d != null && d['passenger'] is Map) ? d['passenger'] as Map : null;
    final pt = (t != null && t['passenger'] is Map) ? t['passenger'] as Map : null;
    final pr = (r != null && r['passenger'] is Map) ? r['passenger'] as Map : null;

    final fields = [
      'name',
      'passengerName',
      'passenger_name',
      'fullName',
      'full_name',
      'displayName',
      'customerName',
      'pax_name',
      'contact_name',
      'passenger'
    ];
    final maps = [p, pd, pt, pr, json, d, t, r];

    for (var m in maps) {
      if (m == null) continue;
      for (var f in fields) {
        final val = m[f];
        if (val is String && val.trim().isNotEmpty && val.toLowerCase() != 'unknown') {
          return val.trim();
        }
      }
    }
    return 'Unknown';
  }

  static String? _parseStation(Map json, List keys) {
    Map? data = json['data'] is Map ? json['data'] : null;
    Map? ticket = json['ticket'] is Map ? json['ticket'] : null;

    String? tryGet(Map m) {
      for (var key in keys) {
        final val = m[key];
        if (val == null) continue;
        String? res;
        if (val is Map) {
          res = val['name']?.toString() ??
              val['title']?.toString() ??
              val['counter_name']?.toString() ??
              (val['counter'] is Map ? val['counter']['name']?.toString() : null);
        } else if (val is String && val.isNotEmpty && !val.startsWith('{')) {
          res = val.trim();
        }
        if (res != null && res.isNotEmpty) {
          return res.replaceAll(RegExp(r'\s+Default\s+Zone', caseSensitive: false), '').trim();
        }
      }
      return null;
    }

    return tryGet(json) ?? tryGet(data ?? {}) ?? tryGet(ticket ?? {});
  }
}
