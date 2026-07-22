import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../main.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../../features/auth/screens/login_screen.dart';

class TripProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _currentUser;
  Trip? _currentTrip;
  List<Trip> _staffTrips = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  String? _otpSentMessage;
  bool _isLastVerificationAlreadyVerified = false;

  TripProvider();

  // Getters
  User? get currentUser => _currentUser;
  Trip? get currentTrip => _currentTrip;
  List<Trip> get staffTrips => _staffTrips;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  String? get otpSentMessage => _otpSentMessage;
  bool get isLastVerificationAlreadyVerified => _isLastVerificationAlreadyVerified;

  // Permission

  bool get canVerify => _currentUser?.hasPermission('TICKET_VALIDATOR_VERIFY_BOARDING') ?? false;
  bool get canManage => _currentUser?.hasPermission('TICKET_VALIDATOR_TRIP_MANAGEMENT') ?? false;
  bool get hasAnyAccess => canVerify || canManage;

  String? get currentErpId => _currentUser?.erpId;

  // Helpers

  void _log(String message, [dynamic data]) {
    if (!kDebugMode) return;
    String cleanMessage = message.replaceAll(RegExp(r'[()\[\]{}\-]'), ' ').trim();
    debugPrint('TripProvider $cleanMessage');
    if (data != null) {
      _printDataCleanly(data);
    }
  }

  void _printDataCleanly(dynamic data, [String prefix = '']) {
    if (data == null) return;
    if (data is Map) {
      data.forEach((key, value) {
        String cleanKey = key.toString().replaceAll(RegExp(r'[()\[\]{}\-]'), ' ').trim();
        _printDataCleanly(value, prefix.isEmpty ? cleanKey : '$prefix $cleanKey');
      });
    } else if (data is List) {
      for (int i = 0; i < data.length; i++) {
        _printDataCleanly(data[i], '$prefix $i');
      }
    } else {
      String valStr = data.toString();
      String cleanValue = valStr.replaceAll(RegExp(r'[()\[\]{}\-]'), ' ').trim();
      debugPrint('$prefix $cleanValue');
    }
  }

  String _normalizeId(String id) {
    return id.trim().replaceAll(RegExp(r'^0+'), '');
  }

  void _setLoading(bool value, {bool refreshing = false}) {
    if (refreshing) {
      _isRefreshing = value;
    } else {
      _isLoading = value;
    }
  }


  // Core Logics  here

  Future<void> fetchStaffTrips({bool showLoading = true, bool useFullList = false}) async {
    if (_isLoading || _isRefreshing) return;

    _setLoading(true, refreshing: !showLoading);
    _errorMessage = null;
    notifyListeners();
    _log('Fetching staff trips (showLoading: $showLoading, useFullList: $useFullList)');

    try {
      //  Use getTripList for Staff Profile trips
      final trips = await _apiService.getTripList();
      
      _log('API Response for trips', trips);
      
      _staffTrips = trips;
      _log('Staff trips updated. Count: ${_staffTrips.length}');

      if (_currentTrip != null) {
        final String canonicalId = _normalizeId(_currentTrip!.id);
        try {
          final updated = _staffTrips.firstWhere(
            (t) => _normalizeId(t.id) == canonicalId
          );
          if (_currentTrip != updated) {
             _currentTrip = updated.copyWith(tickets: _currentTrip!.tickets);
             _log('Active trip ${_currentTrip?.id} metadata updated');
          }
        } catch (_) {
          _log('Active trip $canonicalId not found in latest assignments');
        }
      }
      _errorMessage = null;
    } catch (e) {
      final error = e.toString();
      _log('Fetch staff trips failed: $error');
      if (error.contains('SESSION_EXPIRED')) {
        await logout(silent: true);
        _errorMessage = 'Session expired. Please login again.';
      } else if (error.contains('ENDPOINT_NOT_FOUND')) {
        _errorMessage = 'API Endpoint not found. Please contact support.';
      } else if (error.contains('PERMISSION_DENIED')) {
        _errorMessage = 'Permission Denied: Access Restricted.';
        _staffTrips = [];
        _currentTrip = null;
      } else if (error.contains('SERVER_ERROR')) {
        _errorMessage = 'Server is currently unavailable. Please retry.';
      } else {
        _errorMessage = 'Live sync failed: ${_apiService.parseError(e)}';
      }
    } finally {
      _setLoading(false, refreshing: !showLoading);
      notifyListeners();
    }
  }

  Future<bool> requestOtp(String mobile) async {
    if (_apiService.isThrottled('otp_$mobile', duration: const Duration(seconds: 15))) {
      _errorMessage = 'Action too frequent. Please wait.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _otpSentMessage = null;
    notifyListeners();
    _log('Requesting OTP for $mobile');

    try {
      final msg = await _apiService.getOtp(mobile);
      _otpSentMessage = msg;
      _log('OTP requested successfully');
      return true;
    } catch (e) {
      _errorMessage = _apiService.parseError(e);
      _log('OTP request failed: $_errorMessage');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithOtp(String mobile, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    _log('Attempting login for $mobile');

    try {
      final authData = await _apiService.authenticateStaff(mobile, otp);
      _log('Authentication Raw Response', authData);

      User? userFromAuth;
      if (authData != null) {
        _log('Attempting to parse user from authentication data');
        userFromAuth = User.fromJson(authData);
        _log('Parsed User from Auth', userFromAuth.toJson());
      }

      if (userFromAuth != null) {
        _log('Setting current user for permission check');
        _currentUser = userFromAuth;
        if (!hasAnyAccess) {
          _log('User lacks required permissions', {'verify': canVerify, 'manage': canManage});
          _currentUser = null;
          _log('Login failed Unauthorized permission');
          throw Exception('Unauthorized: You do not have permission to access the Ticket Validator system.');
        }
      }

      try {
        final profileUser = await _apiService.getUserProfile();
        if (profileUser != null) {
          _log('Raw Profile Data Received', profileUser.toJson());
          _currentUser = profileUser.mergeWith(userFromAuth);
          _log('User profile synced and merged UserID ${_currentUser?.id}');
        }
      } catch (e) {
        _log('Profile sync error $e');
        if (userFromAuth != null) {
          _currentUser = userFromAuth;
        } else {
          throw Exception('Profile synchronization failed.');
        }
      }

      if (_currentUser != null) {
        _log('Final Merged User Data', _currentUser!.toJson());
        _log('User ERP ID ${_currentUser?.erpId}');
        await _apiService.saveUser(_currentUser!);
        _log('Login successful');
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _apiService.parseError(e);
      _log('Login failed: $_errorMessage');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTrip(String tripId, {Trip? previewTrip, bool showLoading = true}) async {
    if (previewTrip != null) {
      _currentTrip = previewTrip;
      notifyListeners();
    }

    _setLoading(true, refreshing: !showLoading);
    _errorMessage = null;
    notifyListeners();
    _log('Fetching details for trip $tripId');

    try {
      final String canonicalId = _normalizeId(tripId);
      
      Trip? meta;
      try {
        meta = _staffTrips.firstWhere(
          (t) => _normalizeId(t.id) == canonicalId
        );
      } catch (_) {
        meta = null;
      }

      if (meta == null && previewTrip == null) {
        _log('Trip $tripId is not in assigned list');
        throw Exception('UNASSIGNED_TRIP: Trip $tripId is not in your assigned list.');
      }

      final tickets = await _apiService.getPassengers(tripId);
      _log('Fetched ${tickets.length} tickets for trip $tripId');

      if (_currentTrip != null && _currentTrip!.id == tripId) {
        _currentTrip = _currentTrip!.copyWith(tickets: tickets);
      } else {
        _currentTrip = (meta ?? previewTrip)!.copyWith(tickets: tickets);
      }
    } catch (e) {
      final error = e.toString();
      _log('Fetch trip failed: $error');
      if (error.contains('SESSION_EXPIRED')) {
        await logout(silent: true);
        return;
      }
      if (error.contains('PERMISSION_DENIED')) {
        _errorMessage = 'Access Denied for this trip.';
        _currentTrip = null;
      } else if (error.contains('UNASSIGNED_TRIP')) {
        _errorMessage = 'Diagnostic: Trip not found in assigned list.';
      } else {
        _errorMessage = 'Sync failed: ${_apiService.parseError(e)}';
      }
    } finally {
      _setLoading(false, refreshing: !showLoading);
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Ticket Verification Refactored
  // ---------------------------------------------------------------------------

  Future<List<Ticket>?> verifyTicket(
      String? pnr,
      String? pin, {
        String? encryptedText,
        String? operation,
        String? tripId,
      }) async {
    
    final effectiveTripId = tripId ?? _currentTrip?.id;
    
    if (!_prepareVerification(pnr, effectiveTripId)) return null;

    try {
      final result = await _apiService.verifyTicket(
        pnr,
        pin,
        tripId: effectiveTripId!,
        encryptedText: encryptedText,
      );

      return await _parseVerificationResponse(result, pnr, effectiveTripId);
    } catch (e) {
      return await _handleVerificationError(e, pnr);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _prepareVerification(String? pnr, String? tripId) {
    if (pnr != null && _apiService.isThrottled('verify_$pnr')) {
      _errorMessage = 'Action too frequent. Please wait.';
      notifyListeners();
      return false;
    }

    if (tripId == null) {
      _errorMessage = 'Error: No active trip selected.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _isLastVerificationAlreadyVerified = false;
    notifyListeners();
    _log('Verifying ticket PNR $pnr for trip $tripId');
    return true;
  }

  Future<List<Ticket>?> _parseVerificationResponse(Map<String, dynamic> result, String? pnr, String tripId) async {
    final bool isVerified = result['isVerified'] == true ||
        result['isVerified'].toString().toLowerCase() == 'true' ||
        result['success'] == true ||
        result['status'] == true ||
        result['status']?.toString().toLowerCase() == 'success' ||
        (result.containsKey('pnr') &&
            (result.containsKey('trip') || result.containsKey('ticket')));

    if (isVerified) {
      return _handleVerificationSuccess(result, pnr, tripId);
    } else {
      final String serverMsg = (result['message'] ??
          result['error'] ??
          result['reason'] ??
          'Verification failed')
          .toString();
      
      _log('Verification failed already done $serverMsg');
      
      if (_apiService.isAlreadyVerified(result, serverMsg)) {
        _isLastVerificationAlreadyVerified = true;
        _errorMessage = serverMsg;
        return await _handleAlreadyVerified(pnr, serverMsg, result);
      }
      
      _isLastVerificationAlreadyVerified = false;
      _errorMessage = serverMsg;
      return null;
    }
  }

  List<Ticket>? _handleVerificationSuccess(Map<String, dynamic> result, String? pnr, String tripId) {
    _log('Ticket verified successfully');
    _isLastVerificationAlreadyVerified = false;

    _refreshTripTickets(tripId);

    final dynamic ticketValue = result['tickets'] ?? result['ticket'] ?? result['data'] ?? result;

    if (ticketValue is List) {
      return ticketValue.map((t) => Ticket.fromJson(t as Map)).toList();
    }

    if (ticketValue is Map && ticketValue.containsKey('tickets') && ticketValue['tickets'] is List) {
      return (ticketValue['tickets'] as List).map((t) => Ticket.fromJson(t as Map)).toList();
    }

    dynamic ticketData = ticketValue is Map && ticketValue.containsKey('ticket')
        ? ticketValue['ticket']
        : ticketValue;

    if (ticketData is Map) {
      return [Ticket.fromJson(ticketData)];
    } else if (ticketData is List) {
      return ticketData.map((t) => Ticket.fromJson(t as Map)).toList();
    }

    if (pnr != null && _currentTrip != null) {
      final match = _currentTrip!.tickets.where((t) => t.pnr.trim() == pnr.trim()).toList();
      if (match.isNotEmpty) return match.cast<Ticket>();
    }

    return null;
  }

  Future<List<Ticket>?> _handleVerificationError(dynamic e, String? pnr) async {
    final String errorMsg = _apiService.parseError(e);
    _log('Verification error: $errorMsg');
    
    if (errorMsg.contains('SESSION_EXPIRED')) {
      await logout(silent: true);
      return null;
    }
    
    if (_apiService.isAlreadyVerified(null, errorMsg)) {
      _isLastVerificationAlreadyVerified = true;
      _errorMessage = errorMsg;
      return await _handleAlreadyVerified(pnr, errorMsg, null);
    }
    
    _isLastVerificationAlreadyVerified = false;
    _errorMessage = errorMsg;
    return null;
  }

  Future<void> _refreshTripTickets(String tripId) async {
    try {
      final tickets = await _apiService.getPassengers(tripId);
      if (_currentTrip != null && _currentTrip!.id == tripId) {
        _currentTrip = _currentTrip!.copyWith(tickets: tickets);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<List<Ticket>> _handleAlreadyVerified(
      String? pnr, String serverMsg, dynamic result) async {
    String? effectivePnr = pnr;
    Ticket? serverTicket;

    if (result is Map) {
      final dynamic ticketObj =
          result['ticket'] ?? result['data']?['ticket'] ?? result['data'];
      if (ticketObj != null && ticketObj is Map) {
        try {
          serverTicket = Ticket.fromJson(ticketObj);
          effectivePnr ??= serverTicket.pnr;
        } catch (_) {}
      }
      effectivePnr ??=
          result['pnr']?.toString() ?? result['data']?['pnr']?.toString();
    }

    if (effectivePnr == null || effectivePnr.isEmpty) {
      final pnrRegex = RegExp(r'\d{8,15}');
      final match = pnrRegex.firstMatch(serverMsg);
      if (match != null) effectivePnr = match.group(0);
    }

    if (_currentTrip != null) {
      _refreshTripTickets(_currentTrip!.id);
    }

    if (serverTicket != null) return [serverTicket];

    if (effectivePnr != null && _currentTrip != null) {
      final match = _currentTrip!.tickets
          .where((t) => t.pnr.trim() == effectivePnr!.trim())
          .toList();
      if (match.isNotEmpty) return match;
    }

    return [
      Ticket(
        pnr: effectivePnr ?? 'N/A',
        seatNo: 'N/A',
        passengerName: 'Already Verified',
        isVerified: true,
      )
    ];
  }

  // ---------------------------------------------------------------------------
  // Profile & Assignments
  // ---------------------------------------------------------------------------

  Future<bool> tryAutoLogin() async {
    try {
      final user = await _apiService.getUser();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        _log('Auto-login successful for ${user.id}');
        return true;
      }
    } catch (_) {
    }
    return false;
  }

  Future<void> refreshProfile() async {
    _log('Refreshing user profile');
    try {
      final profileUser = await _apiService.getUserProfile();
      if (profileUser != null) {
        _currentUser = profileUser.mergeWith(_currentUser);
        notifyListeners();
        _log('Profile refreshed');
      }
    } catch (e) {
      if (e.toString().contains('SESSION_EXPIRED')) {
        await logout(silent: true);
      }
      _log('Profile refresh error: $e');
    }
  }

  Future<bool> resendPin(String pnr) async {
    _log('Resending PIN for PNR $pnr');
    try {
      await _apiService.resendPin(pnr);
      return true;
    } catch (e) {
      _errorMessage = _apiService.parseError(e);
      _log('Resend PIN failed: $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTripAssignments({
    required String tripId,
    int? driverId,
    int? helperId,
    int? vehicleId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    _log('Updating assignments for trip $tripId');

    try {
      await _apiService.manageTrip(
        tripId: tripId,
        driverId: driverId,
        helperId: helperId,
        vehicleId: vehicleId,
      );
      
      // Fetch latest assignments immediately without extra delay
      final trips = await _apiService.getTripList();
      _staffTrips = trips;
      
      // Update the active trip object in memory immediately for live sync
      final String canonicalId = _normalizeId(tripId);
      try {
        final updatedTrip = _staffTrips.firstWhere(
          (t) => _normalizeId(t.id) == canonicalId
        );
        
        // Preserve tickets but update staff/vehicle metadata
        _currentTrip = updatedTrip.copyWith(
          tickets: _currentTrip?.id == updatedTrip.id ? _currentTrip?.tickets : null
        );
      } catch (e) {
        _log('Could not find updated trip in list: $e');
      }

      _log('Assignments updated and current trip synced');
      return true;
    } catch (e) {
      _errorMessage = _apiService.parseError(e);
      _log('Update assignments failed: $_errorMessage');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout({bool silent = false}) async {
    _log('Logging out');
    _currentUser = null;
    _currentTrip = null;
    _staffTrips = [];
    await _apiService.clearAuth();
    
    if (!silent) {
      notifyListeners();
    }
    
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
