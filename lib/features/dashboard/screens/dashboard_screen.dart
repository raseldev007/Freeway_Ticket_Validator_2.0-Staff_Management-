import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/screens/login_screen.dart';
import 'passenger_list_screen.dart';
import 'how_to_use_screen.dart';
import 'staff_profile_screen.dart';
import 'manage_trip_screen.dart';
import '../../verification/screens/manual_verification_screen.dart';
import '../../verification/screens/qr_verification_screen.dart';
import '../../../core/models/models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
    _setupAutoRefresh();
  }

  void _setupAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(hours: 2), (timer) {
      if (mounted) {
        final provider = context.read<TripProvider>();
        if (!provider.isLoading) {
          provider.fetchStaffTrips(showLoading: false);
        }
      }
    });
  }

  Future<void> _checkForUpdate() async {
    if (kDebugMode || !Platform.isAndroid) return;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      debugPrint('Update check failed $e');
      await Future.delayed(const Duration(minutes: 1));
      if (mounted) _checkForUpdate();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleQrVerification() async {
    HapticFeedback.selectionClick();
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QrVerificationScreen()),
      );
      if (mounted) {
        context.read<TripProvider>().fetchStaffTrips(showLoading: false);
      }
    }
  }

  Future<void> _handleManualVerification() async {
    HapticFeedback.selectionClick();
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ManualVerificationScreen(),
        ),
      );
      if (mounted) {
        context.read<TripProvider>().fetchStaffTrips(showLoading: false);
      }
    }
  }

  Future<void> _handlePassengerList() async {
    HapticFeedback.selectionClick();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PassengerListScreen()),
    );
    if (mounted) {
      context.read<TripProvider>().fetchStaffTrips();
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('hh:mm a').format(dateTime.toUtc().add(const Duration(hours: 6)));
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(dateTime.toUtc().add(const Duration(hours: 6)));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TripProvider>(
      builder: (context, provider, child) {
        final user = provider.currentUser;
        final currentTrip = provider.currentTrip;

        if (provider.isLoading) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: _buildAppBar(provider),
            body: _buildSkeletonUI(),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(provider),
          body: currentTrip == null
              ? _buildEmptyOrErrorState(provider)
              : RefreshIndicator(
                  onRefresh: () async {
                    await provider.refreshProfile();
                    await provider.fetchStaffTrips(showLoading: false);
                    if (provider.currentTrip != null) {
                      await provider.fetchTrip(provider.currentTrip!.id);
                    }
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6ECE5),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.05), width: 1),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: CircleAvatar(
                                    radius: 35,
                                    backgroundColor: Colors.white,
                                    child: ClipOval(
                                      child: (user?.profilePicUrl?.isNotEmpty ?? false)
                                          ? Image.network(
                                              user!.profilePicUrl!,
                                              width: 70,
                                              height: 70,
                                              cacheWidth: 140,
                                              cacheHeight: 140,
                                              fit: BoxFit.contain,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Shimmer.fromColors(
                                                  baseColor: Colors.grey[300]!,
                                                  highlightColor: Colors.grey[100]!,
                                                  child: Container(width: 70, height: 70, color: Colors.white),
                                                );
                                              },
                                              errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(user),
                                            )
                                          : _buildAvatarFallback(user),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          user?.fullName ?? 'Staff Member',
                                          style: GoogleFonts.inter(
                                            color: AppColors.primary,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          children: [
                                            const SizedBox(width: 4),
                                            Text(
                                              user?.designation ?? 'STAFF',
                                              style: GoogleFonts.inter(
                                                color: AppColors.textSecondary,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.verified_user_outlined, color: Colors.white, size: 16),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('Active Trip Details',
                                  style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.8)),
                              const SizedBox(height: 10),
                              _buildTripInfoCard(currentTrip)
                                  .animate()
                                  .fadeIn()
                                  .scale(begin: const Offset(0.98, 0.98)),
                              const SizedBox(height: 15),
                              
                              // Staff & Vehicle Details
                              _buildStaffInfoRow(
                                Icons.bus_alert, 
                                'Vehicle No', 
                                currentTrip.vehicleNo?.toUpperCase() ?? 'N/A',
                                subValue: currentTrip.vehicle?.manufacturer?.toUpperCase(),
                              ),
                              _buildStaffInfoRow(
                                Icons.person, 
                                'Driver Name', 
                                (currentTrip.driverName ?? 'Not Assigned').toUpperCase(),
                                mobile: currentTrip.driver?.mobile,
                                subValue: currentTrip.driver != null ? 'EMP-ID: ${currentTrip.driverErpId ?? "N/A"}' : null,
                              ),
                              _buildStaffInfoRow(
                                Icons.group_outlined, 
                                'Helper Name', 
                                (currentTrip.helperName ?? 'Not Assigned').toUpperCase(),
                                mobile: currentTrip.helper?.mobile,
                                subValue: currentTrip.helper != null ? 'EMP-ID: ${currentTrip.helperErpId ?? "N/A"}' : null,
                              ),
                                  
                              if (user?.hasPermission('TICKET_VALIDATOR_TRIP_MANAGEMENT') ?? false)
                                _buildManageTripButton(currentTrip),

                              const SizedBox(height: 2),
                              _buildActionButton(
                                onPressed: _handlePassengerList,
                                icon: Icons.group_rounded,
                                label: 'View Passenger List',
                                isPrimary: true,
                              ).animate().slideY(begin: 0.1),
                              if (user?.hasPermission('TICKET_VALIDATOR_VERIFY_BOARDING') ?? true) ...[
                                const SizedBox(height: 2),
                                _buildActionButton(
                                  onPressed: _handleQrVerification,
                                  icon: Icons.qr_code_scanner_rounded,
                                  label: 'Scan QR Code',
                                  isOutline: true,
                                ).animate().slideY(begin: 0.1, delay: 100.ms),
                                const SizedBox(height: 2),
                                _buildActionButton(
                                  onPressed: _handleManualVerification,
                                  icon: Icons.edit_note_rounded,
                                  label: 'Manual Verification',
                                  isSecondary: true,
                                ).animate().slideY(begin: 0.1, delay: 200.ms),
                              ],
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(TripProvider provider) {
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leading: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40),
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: AppColors.primary,
        ),
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const StaffProfileScreen()),
            );
          }
        },
      ),
      toolbarHeight: 65,
      title: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 100),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'How to Use',
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HowToUseScreen()),
            );
          },
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'Logout',
          onPressed: () {
            provider.logout();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          },
          icon: const Icon(Icons.logout_rounded, size: 22),
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildEmptyOrErrorState(TripProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage ?? 'No Trip Selected',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            if (provider.errorMessage != null)
              ElevatedButton(
                onPressed: () => provider.fetchStaffTrips(),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Retry Sync', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripInfoCard(Trip trip) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFFEF5350)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.directions_bus_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      _buildCardDivider(height: 45),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('#',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary)),
                                const SizedBox(width: 2),
                                Text(
                                  trip.id.toUpperCase(),
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(trip.fromCode.toUpperCase(),
                                    style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                        letterSpacing: -0.5)),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(trip.toCode.toUpperCase(),
                                    style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                        letterSpacing: -0.5)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey[200], indent: 15, endIndent: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    children: [
                      _buildResponsiveTripStat(
                        icon: Icons.calendar_today_outlined,
                        label: 'TRIP DATE',
                        value: _formatDate(trip.departureTime),
                      ),
                      _buildCardDivider(height: 32),
                      _buildResponsiveTripStat(
                        icon: Icons.access_time_rounded,
                        label: 'DEP. TIME',
                        value: _formatDateTime(trip.departureTime),
                      ),
                      _buildCardDivider(height: 32),
                      _buildResponsiveTripStat(
                        icon: Icons.directions_bus_outlined,
                        label: 'COACH',
                        value: trip.coachCode ?? 'N/A',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffInfoRow(IconData icon, String label, String value, {String? subValue, String? mobile}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (subValue != null && subValue.isNotEmpty && subValue.toLowerCase() != 'null')
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          subValue,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (mobile != null && mobile.isNotEmpty && mobile.toLowerCase() != 'null')
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone_android_rounded, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          mobile,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDivider({double height = 30}) {
    return Container(
      height: height,
      width: 1.2,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildResponsiveTripStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: AppColors.primary.withValues(alpha: 0.7)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF9E9E9E),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageTripButton(Trip trip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          onPressed: () async {
            HapticFeedback.lightImpact();
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ManageTripScreen(trip: trip)),
            );
            
            // If we came back after a successful update, refresh the dashboard data
            if (result == true && mounted) {
              context.read<TripProvider>().fetchStaffTrips(showLoading: false);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE6ECE5),
            foregroundColor: AppColors.primary,
            elevation: 0,
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.edit_note, size: 22),
              const SizedBox(width: 10),
              Text(
                'Manage Trip',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      {required VoidCallback onPressed,
        required IconData icon,
        required String label,
        bool isPrimary = false,
        bool isSecondary = false,
        bool isOutline = false}) {
    Color bg = Colors.white;
    Color fg = AppColors.primary;
    BorderSide? border;
    double elevation = 0;

    if (isPrimary) {
      bg = AppColors.primary;
      fg = Colors.white;
      elevation = 2;
    } else if (isSecondary) {
      bg = const Color(0xFFFEF1F1);
      fg = AppColors.primary;
    } else if (isOutline) {
      bg = Colors.white;
      fg = AppColors.primary;
      border = const BorderSide(color: AppColors.primary, width: 1.5);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            elevation: elevation,
            shadowColor: Colors.black.withValues(alpha: 0.2),
            side: border,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(User? user) {
    String initial = user != null && user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '';
    return Container(
      width: 70,
      height: 70,
      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 26,
        ),
      ),
    );
  }

  Widget _buildSkeletonUI() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      period: const Duration(seconds: 2),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 140,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 90,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              height: 25,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 30),
            ...List.generate(3, (index) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 62,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
