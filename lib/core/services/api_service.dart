import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:freeway_ticket_validator/core/models/models.dart';

class ApiService {
  static SharedPreferences? _prefs;
  
  Future<SharedPreferences> _getPrefs() async {
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  static const String baseUrl = 'https://shohagh.sales.freeway.dev/api/ticketValidator';
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const Duration timeoutDuration = Duration(seconds: 12);

  Future<bool> hasInternet() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  Future<void> saveToken(String token) async {
    final prefs = await _getPrefs();
    await prefs.setString(tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(tokenKey);
  }

  Future<void> saveUser(User user) async {
    final prefs = await _getPrefs();
    await prefs.setString(userKey, jsonEncode(user.toJson()));
  }

  Future<User?> getUser() async {
    try {
      final prefs = await _getPrefs();
      final userStr = prefs.getString(userKey);
      if (userStr != null) {
        return User.fromJson(jsonDecode(userStr));
      }
    } catch (_) {
    }
    return null;
  }

  Future<void> clearAuth() async {
    final prefs = await _getPrefs();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
  }

  Future<void> clearToken() async {
    final prefs = await _getPrefs();
    await prefs.remove(tokenKey);
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  final Map<String, DateTime> _lastRequestTime = {};
  static const Duration _defaultCoolDown = Duration(seconds: 2);

  bool isThrottled(String key, {Duration? duration}) {
    final now = DateTime.now();
    final lastTime = _lastRequestTime[key];
    if (lastTime != null && now.difference(lastTime) < (duration ?? _defaultCoolDown)) {
      return true;
    }
    _lastRequestTime[key] = now;

    if (_lastRequestTime.length > 50) {
      _lastRequestTime.removeWhere((k, v) => now.difference(v) > const Duration(minutes: 5));
    }
    return false;
  }

  String parseError(dynamic e) {
    final error = e.toString();
    if (error.startsWith('Exception: ')) {
      return error.substring(11);
    }
    return error;
  }

  dynamic _processResponse(http.Response response, String endpoint) {
    // Unauthorized 401 : Logout
    if (response.statusCode == 401) {
      clearAuth();
      throw Exception('SESSION_EXPIRED');
    }

    //Permission Denied 403
    if (response.statusCode == 403) {
      throw Exception('PERMISSION_DENIED');
    }

    //Rate Limiting 429
    if (response.statusCode == 429) {
      throw Exception('Action too frequent. Please wait a moment.');
    }

    //Not Found 404 -> Treat as Empty List/Data per requirement
    if (response.statusCode == 404) {
      final cType = response.headers['content-type'] ?? '';
      return cType.contains('application/json') ? {} : null;
    }

    //Server Error 500
    if (response.statusCode >= 500) {
      throw Exception('SERVER_ERROR');
    }

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw Exception('INVALID_RESPONSE');
    }

    try {
      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('PARSE_ERROR: $e');
    }
  }

  Future<http.Response> get(String endpoint, {bool useAuth = true, String? customBase, int retries = 2}) async {
    final url = '${customBase ?? baseUrl}$endpoint';
    _cleanPrint('API GET Request', url);
    try {
      final headers = useAuth
          ? await _authHeaders()
          : {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            };

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(timeoutDuration);

      _cleanPrint('API GET Response', '$endpoint ${response.statusCode}');

      if (response.statusCode >= 500 && retries > 0) {
        await Future.delayed(const Duration(seconds: 1));
        return get(endpoint, useAuth: useAuth, customBase: customBase, retries: retries - 1);
      }

      return response;
    } on SocketException {
      if (retries > 0) {
        await Future.delayed(const Duration(seconds: 1));
        return get(endpoint, useAuth: useAuth, customBase: customBase, retries: retries - 1);
      }
      throw Exception('Network unreachable. Please check your internet connection.');
    } on HttpException {
      if (retries > 0) return get(endpoint, useAuth: useAuth, customBase: customBase, retries: retries - 1);
      throw Exception('Connection closed unexpectedly. Please try again.');
    } on TimeoutException {
      if (retries > 0) return get(endpoint, useAuth: useAuth, customBase: customBase, retries: retries - 1);
      throw Exception('Connection timed out. Please try again.');
    } on http.ClientException {
      if (retries > 0) return get(endpoint, useAuth: useAuth, customBase: customBase, retries: retries - 1);
      throw Exception('Connection failed. Please check your network.');
    } catch (_) {
      if (retries > 0) return get(endpoint, useAuth: useAuth, customBase: customBase, retries: retries - 1);
      rethrow;
    }
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body,
      {int retries = 2, String? customBase}) async {
    final url = '${customBase ?? baseUrl}$endpoint';
    _cleanPrint('API POST Request', url);
    
    try {
      final headers = await _authHeaders();

      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(timeoutDuration);

      _cleanPrint('API POST Response', '$endpoint ${response.statusCode}');

      if (response.statusCode >= 500 && retries > 0) {
        await Future.delayed(const Duration(seconds: 1));
        return post(endpoint, body, retries: retries - 1, customBase: customBase);
      }

      return response;
    } on TimeoutException {
      if (retries > 0) {
        return post(endpoint, body, retries: retries - 1, customBase: customBase);
      }
      throw Exception('Connection timed out. Please try again.');
    } on SocketException {
      throw Exception('Network unreachable. Please check your internet connection.');
    } on HttpException {
      if (retries > 0) {
        return post(endpoint, body, retries: retries - 1, customBase: customBase);
      }
      throw Exception('Connection closed unexpectedly. Please try again.');
    } on http.ClientException {
      if (retries > 0) {
        return post(endpoint, body, retries: retries - 1, customBase: customBase);
      }
      throw Exception('Connection failed. Please check your network.');
    } catch (e) {
      if (retries > 0) {
        return post(endpoint, body, retries: retries - 1, customBase: customBase);
      }
      rethrow;
    }
  }

  Future<String> getOtp(String mobile) async {
    final startTime = DateTime.now();
    http.Response? response;
    try {
      response = await get('/getOtp/$mobile', useAuth: false);
      
      _logApiCall(
        response: response,
        startTime: startTime,
        objectType: 'String (OTP Message)',
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        final reason = _getErrorReason(response.body, 'Failed to send OTP');
        throw Exception(reason);
      }
    } catch (e, stack) {
      if (response != null) {
        _logApiCall(
          response: response,
          startTime: startTime,
          exception: e,
          stackTrace: stack,
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> authenticateStaff(String mobile, String otp) async {
     final startTime = DateTime.now();
    http.Response? response;
    dynamic decoded;
    
    try {
      response = await get('/authenticateStaff/$mobile/$otp', useAuth: false);
      decoded = _processResponse(response, '/authenticateStaff');

      if (decoded != null && decoded['token'] != null) {
        await saveToken(decoded['token']);
        if (kDebugMode) debugPrint('ApiService JWT Saved from Login');
      }

      User? user;
      if (decoded != null && decoded['user'] != null) {
        user = User.fromJson(decoded);
        await saveUser(user);
        if (kDebugMode) debugPrint('ApiService User Profile Saved from Login');
      }

      // Explicitly check erpId from backend
      final rawData = (decoded['user'] is Map) ? decoded['user'] : (decoded['data'] is Map ? decoded['data'] : decoded);
      _cleanPrint('Raw ERP ID from Backend', rawData['erpId']);
      _cleanPrint('Raw Staff ID from Backend', rawData['staffId']);

      _logApiCall(
        response: response,
        startTime: startTime,
        rawJson: decoded,
        parsedModels: user,
        objectType: 'LoginResponse',
      );

      return Map<String, dynamic>.from(decoded ?? {});
    } catch (e, stack) {
      if (response != null) {
        _logApiCall(
          response: response,
          startTime: startTime,
          rawJson: decoded,
          exception: e,
          stackTrace: stack,
        );
      }
      rethrow;
    }
  }

  String _getErrorReason(String body, String defaultMessage) {
    try {
      final data = jsonDecode(body);
      return data['reason'] ?? data['message'] ?? defaultMessage;
    } catch (_) {
      return defaultMessage;
    }
  }

  Future<List<Ticket>> getPassengers(String tripId, {SeatTypeStatus? seatStatus, bool forceRefresh = false}) async {
    final startTime = DateTime.now();
    final Map<String, dynamic> body = {
      'tripId': tripId,
      if (seatStatus != null) 'seatTypeStatus': seatStatus.value,
    };
    
    http.Response? response;
    dynamic decoded;
    List<Ticket> tickets = [];
    
    try {
      response = await post('/passengers', body);
      decoded = _processResponse(response, '/passengers');
      
      List<dynamic> data = [];
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map) {
        data = decoded['data'] ?? decoded['tickets'] ?? decoded['passengers'] ?? [];
      }
      
      final int totalItems = data.length;

      // Safe Parsing: Individual item errors won't crash the loop
      for (var item in data) {
        if (item is Map) {
          try {
            tickets.add(Ticket.fromJson(Map<String, dynamic>.from(item)));
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Ticket Parsing Error: $e for item: $item');
            }
          }
        }
      }

      if (kDebugMode && tickets.length < totalItems) {
        debugPrint('Ticket Parsing: Successfully loaded ${tickets.length} out of $totalItems items');
      }

      //Memorysafe logging for large datasets


      _logApiCall(
        response: response,
        startTime: startTime,
        requestBody: body,
        rawJson: totalItems > 30 ? '[Large Dataset: $totalItems items - Hidden for stability]' : decoded,
        objectType: 'List<Ticket>',
      );
      
      return tickets;
    } catch (e, stack) {
      if (response != null) {
        _logApiCall(
          response: response,
          startTime: startTime,
          requestBody: body,
          exception: e,
          stackTrace: stack,
        );
      }
      rethrow;
    }
  }

  Future<User?> getUserProfile() async {
    final startTime = DateTime.now();
    http.Response? response;
    dynamic decoded;
    User? user;
    
    try {
      response = await get('/profile');
      decoded = _processResponse(response, '/profile');
      
      if (decoded is Map<String, dynamic>) {
        user = User.fromJson(decoded);
        await saveUser(user);

        final rawData = (decoded['user'] is Map) ? decoded['user'] : (decoded['data'] is Map ? decoded['data'] : decoded);
        _cleanPrint('Profile Raw ERP ID', rawData['erpId']);
      }

      _logApiCall(
        response: response,
        startTime: startTime,
        rawJson: decoded,
        parsedModels: user,
        objectType: 'User',
      );

      if (user != null) return user;
      throw Exception('Failed to load profile from server');
    } catch (e, stack) {
      if (response != null) {
        _logApiCall(
          response: response,
          startTime: startTime,
          rawJson: decoded,
          exception: e,
          stackTrace: stack,
        );
      }
      rethrow;
    }
  }

  void _cleanPrint(String label, dynamic value) {
    if (!kDebugMode || value == null) return;
    
    try {
     // Check length FIRST without creating massive strings - handles List

      if (value is List) {
        if (value.length > 15) {
          debugPrint('$label: [List with ${value.length} items. Summary: ${value.take(2).toList()}...]');
          return;
        }
      }
      
      //Check key count FIRST -  Handle Maps


      if (value is Map) {
        if (value.length > 25) {
          debugPrint('$label: [Map with ${value.length} keys. Keys: ${value.keys.take(5).toList()}...]');
          return;
        }
      }

      // String length check before  any heavy processing

      if (value is String) {
        if (value.length > 1200) {
          debugPrint('$label: [Large String (${value.length} chars) - Truncated for stability]');
          debugPrint('${value.substring(0, 1000)}...');
          return;
        }
      }

      String dataStr = value.toString();
      if (dataStr.length > 1500) {
        debugPrint('$label: [Large Data (${dataStr.length} chars) - Truncated for stability]');
        debugPrint('${dataStr.substring(0, 1000)}...');
      } else {
        debugPrint('$label: $dataStr');
      }
    } catch (e) {
      debugPrint('$label: [Log suppressed for stability]');
    }
  }

  void _logApiCall({
    required http.Response response,
    required DateTime startTime,
    dynamic requestBody,
    dynamic rawJson,
    dynamic parsedModels,
    String? objectType,
    dynamic exception,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;
    
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    final request = response.request;

    _cleanPrint('REQUEST', '');
    _cleanPrint('Endpoint', request?.url.path ?? 'unknown');
    _cleanPrint('Method', request?.method ?? 'unknown');
    _cleanPrint('URL', request?.url.toString() ?? 'unknown');
    if (requestBody != null) {
      _cleanPrint('Payload', requestBody);
    }

    _cleanPrint('RESPONSE', '');
    _cleanPrint('Status', response.statusCode);
    _cleanPrint('Duration Ms', duration.inMilliseconds);
    
    // If the dataset is large, don't pass the whole thing to _cleanPrint

    dynamic safeData = rawJson;
    if (rawJson is List && rawJson.length > 30) {
      safeData = '[Large dataset: ${rawJson.length} items hidden for memory stability]';
    } else if (response.body.length > 5000 && rawJson == null) {
      safeData = '[Body too large (${response.body.length} chars) - Truncated]';
    }

    if (safeData != null) {
      _cleanPrint('Data', safeData);
    } else {
      _cleanPrint('Raw Body', response.body);
    }

    if (exception != null) {
      _cleanPrint('Exception', exception.toString());
    }
    
    debugPrint('LOG END');
  }

  List<Trip> _parseTrips(dynamic decoded, {String label = 'Trips'}) {
    List<dynamic> dataList = [];
    if (decoded is List) {
      dataList = decoded;
    } else if (decoded is Map) {
      dataList = decoded['data'] ?? decoded['trips'] ?? decoded['result'] ?? decoded['items'] ?? [];
    }

    final int totalCount = dataList.length;
    List<Trip> trips = [];

    for (var item in dataList) {
      if (item is Map) {
        try {
          trips.add(Trip.fromJson(Map<String, dynamic>.from(item)));
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Trip Parsing Error: $e for item: $item');
          }
        }
      }
    }

    if (kDebugMode && trips.length < totalCount) {
      debugPrint('$label Parsing: Successfully loaded ${trips.length} out of $totalCount items');
    }

    return trips;
  }

  Future<List<Trip>> getTodayTrips() async {
    final startTime = DateTime.now();
    http.Response? response;
    dynamic decoded;
    
    try {
      response = await get('/getTodayTrips');
      decoded = _processResponse(response, '/getTodayTrips');
      final trips = _parseTrips(decoded, label: 'TODAY TRIPS');
      
      _logApiCall(
        response: response,
        startTime: startTime,
        rawJson: decoded,
        parsedModels: trips,
        objectType: 'List<Trip>',
      );
      
      return trips;
    } catch (e, stack) {
      if (response != null) {
        _logApiCall(
          response: response,
          startTime: startTime,
          rawJson: decoded,
          exception: e,
          stackTrace: stack,
        );
      }
      rethrow;
    }
  }

  Future<List<Trip>> getTripList() async {
    final startTime = DateTime.now();
    http.Response? response;
    dynamic decoded;
    
    try {
      response = await get('/getTripList');
      decoded = _processResponse(response, '/getTripList');
      final trips = _parseTrips(decoded, label: 'TRIP LIST');

      _logApiCall(
        response: response,
        startTime: startTime,
        rawJson: decoded,
        parsedModels: trips,
        objectType: 'List<Trip>',
      );

      return trips;
    } catch (e, stack) {
      if (response != null) {
        _logApiCall(
          response: response,
          startTime: startTime,
          rawJson: decoded,
          exception: e,
          stackTrace: stack,
        );
      }
      rethrow;
    }
  }

  // getTripList

  
  Future<List<Trip>> getStaffTrips() async {
    if (kDebugMode) debugPrint('ApiService Fetching trips for Staff Profile using getTripList');
    return await getTripList();
  }


  Future<Map<String, dynamic>> validateTripId(String tripId) async {
    final startTime = DateTime.now();
    http.Response? response;
    dynamic decoded;
    try {
      response = await get('/validateTripId/$tripId');
      decoded = _processResponse(response, '/validateTripId');
      
      _logApiCall(
        response: response,
        startTime: startTime,
        rawJson: decoded,
        objectType: 'Map (Trip Validation)',
      );
      
      return Map<String, dynamic>.from(decoded ?? {});
    } catch (e, stack) {
      if (response != null) {
        _logApiCall(
          response: response,
          startTime: startTime,
          rawJson: decoded,
          exception: e,
          stackTrace: stack,
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyTicket(String? pnr, String? pin, {String? tripId, String? encryptedText}) async {
    final startTime = DateTime.now();
    final String? pnrClean = pnr?.trim();
    final String? pinClean = pin?.trim();
    final String? encryptedClean = encryptedText?.trim();

    final Map<String, dynamic> body = {
      'tripId': tripId?.trim() ?? '',
    };

    if (pnrClean != null && pnrClean.isNotEmpty) {
      body['pnr'] = pnrClean;
    }
    if (pinClean != null && pinClean.isNotEmpty) {
      body['pin'] = pinClean;
    }
    if (encryptedClean != null && encryptedClean.isNotEmpty) {
      body['encryptedText'] = encryptedClean;
    }

    if ((body['pnr'] == null || body['pnr'].isEmpty) && (body['encryptedText'] == null || body['encryptedText'].isEmpty)) {
      throw Exception('PNR or Encrypted Text is required');
    }

    http.Response? response;
    dynamic decoded;
    try {
      response = await post('/verifyTicket', body);
      decoded = _processResponse(response, '/verifyTicket');

      _logApiCall(
        response: response,
        startTime: startTime,
        requestBody: body,
        rawJson: decoded,
        objectType: 'Map (Ticket Verification)',
      );

      return Map<String, dynamic>.from(decoded ?? {});
    } catch (e, stack) {
      if (response != null) {
        _logApiCall(
          response: response,
          startTime: startTime,
          requestBody: body,
          rawJson: decoded,
          exception: e,
          stackTrace: stack,
        );
      }
      rethrow;
    }
  }

  Future<String> resendPin(String pnr) async {
    final startTime = DateTime.now();
    http.Response? response;
    try {
      response = await get('/resendPin/$pnr');
      _processResponse(response, '/resendPin');
      
      _logApiCall(
        response: response,
        startTime: startTime,
        objectType: 'String (Resend PIN Response)',
      );

      if (response.statusCode == 200) return response.body;
      throw Exception('Failed to resend PIN');
    } catch (e, stack) {
      if (response != null) {
        _logApiCall(
          response: response,
          startTime: startTime,
          exception: e,
          stackTrace: stack,
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> manageTrip({
    required String tripId,
    int? driverId,
    int? helperId,
    int? vehicleId,
  }) async {
    final startTime = DateTime.now();
    if (kDebugMode) debugPrint('ApiService Calling POST /manageTrip');
    final Map<String, dynamic> body = {
      'id': tripId,
    };

    if (driverId != null) body['driver'] = {'id': driverId};
    if (helperId != null) body['helper'] = {'id': helperId};
    if (vehicleId != null) body['vehicle'] = {'id': vehicleId};

    http.Response? response;
    dynamic decoded;
    try {
      response = await post('/manageTrip', body);
      decoded = _processResponse(response, '/manageTrip');
      
      _logApiCall(
        response: response,
        startTime: startTime,
        requestBody: body,
        rawJson: decoded,
        objectType: 'Map (Manage Trip)',
      );

      if (kDebugMode) debugPrint('ApiService Assignment Success');
      return Map<String, dynamic>.from(decoded ?? {});
    } catch (e, stack) {
      if (response != null) {
        _logApiCall(
          response: response,
          startTime: startTime,
          requestBody: body,
          rawJson: decoded,
          exception: e,
          stackTrace: stack,
        );
      }
      rethrow;
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> getTripStaffInfo() async {
    final startTime = DateTime.now();
    if (kDebugMode) debugPrint('ApiService Calling GET /staffInfo');
    
    http.Response? response;
    dynamic decoded;
    try {
      response = await get('/staffInfo');
      decoded = _processResponse(response, '/staffInfo');
      
      _logApiCall(
        response: response,
        startTime: startTime,
        rawJson: decoded,
        objectType: 'StaffInfoLists',
      );

      final Map<String, dynamic> data = (decoded is Map) ? Map<String, dynamic>.from(decoded) : {};
      
      final supervisors = List<Map<String, dynamic>>.from(data['supervisors'] ?? []);
      final drivers = List<Map<String, dynamic>>.from(data['drivers'] ?? []);
      final helpers = List<Map<String, dynamic>>.from(data['helpers'] ?? []);
      final vehicles = List<Map<String, dynamic>>.from(data['vehicles'] ?? []);

      if (kDebugMode) {
        debugPrint('STAFF INFO DEBUG');
        if (drivers.isNotEmpty) debugPrint('First Driver Data: ${drivers.first}');
        if (helpers.isNotEmpty) debugPrint('First Helper Data: ${helpers.first}');
        debugPrint(' ');
        debugPrint('Driver Count ${drivers.length}');
        debugPrint('Helper Count ${helpers.length}');
        debugPrint('Vehicle Count ${vehicles.length}');
      }

      return {
        'supervisors': supervisors,
        'drivers': drivers,
        'helpers': helpers,
        'vehicles': vehicles,
      };
    } catch (e, stack) {
      if (response != null) {
        _logApiCall(
          response: response,
          startTime: startTime,
          rawJson: decoded,
          exception: e,
          stackTrace: stack,
        );
      }
      rethrow;
    }
  }

  bool isAlreadyVerified(dynamic result, String message) {
    final msg = message.toLowerCase();
    return msg.contains('already verified') ||
        msg.contains('already boarded') ||
        msg.contains('already success') ||
        msg.contains('already used') ||
        msg.contains('already valid') ||
        msg.contains('already recorded') ||
        msg.contains('status is boarded') ||
        msg.contains('ticket is boarded') ||
        (result is Map &&
            (result['code']?.toString().toUpperCase() == 'ALREADY_VERIFIED' ||
                result['code']?.toString().toUpperCase() == 'ALREADY_BOARDED' ||
                result['status']?.toString().toLowerCase() ==
                    'already_verified' ||
                result['status']?.toString().toLowerCase() ==
                    'already_boarded'));
  }
}

