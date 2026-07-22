import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui';
import 'package:in_app_update/in_app_update.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';
import '../../auth/screens/login_screen.dart';
import 'dashboard_screen.dart';
import 'how_to_use_screen.dart';

class StaffProfileScreen extends StatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

enum TripFilter { all, today, tomorrow }

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  bool _isNavigating = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchVisible = false;
  String _searchQuery = '';
  TripFilter _selectedFilter = TripFilter.all;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().fetchStaffTrips();
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
      await Future.delayed(const Duration(minutes: 5));
      if (mounted) _checkForUpdate();
    }
  }

  Future<void> _handleTripSelection(Trip trip) async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      HapticFeedback.mediumImpact();
      context.read<TripProvider>().fetchTrip(trip.id, previewTrip: trip);
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } finally {
      _isNavigating = false;
    }

    if (mounted) {
      context.read<TripProvider>().fetchStaffTrips(showLoading: false);
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    final localTime = dateTime.toUtc().add(const Duration(hours: 6));
    return DateFormat('hh:mm a').format(localTime);
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    final localTime = dateTime.toUtc().add(const Duration(hours: 6));
    return DateFormat('dd MMM, yyyy').format(localTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
        leadingWidth: 80,
        leading: const SizedBox(),
        title: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 100),
          child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
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
          const SizedBox(width: 10),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              context.read<TripProvider>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF2E7D32), size: 22),
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: Consumer<TripProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading || provider.isRefreshing) {
            return _buildSkeletonUI();
          }

          final allTrips = provider.staffTrips;
          
          // Calculate counts before any filtering
          final now = DateTime.now().toUtc().add(const Duration(hours: 6));
          final todayDate = DateTime(now.year, now.month, now.day);
          final tomorrowDate = todayDate.add(const Duration(days: 1));

          int countAll = allTrips.length;
          int countToday = allTrips.where((t) {
            if (t.departureTime == null) return false;
            final d = t.departureTime!.toUtc().add(const Duration(hours: 6));
            return DateTime(d.year, d.month, d.day).isAtSameMomentAs(todayDate);
          }).length;
          int countTomorrow = allTrips.where((t) {
            if (t.departureTime == null) return false;
            final d = t.departureTime!.toUtc().add(const Duration(hours: 6));
            return DateTime(d.year, d.month, d.day).isAtSameMomentAs(tomorrowDate);
          }).length;

          // Apply date filter
          var filteredByDate = allTrips;
          if (_selectedFilter == TripFilter.today) {
            filteredByDate = allTrips.where((t) {
              if (t.departureTime == null) return false;
              final d = t.departureTime!.toUtc().add(const Duration(hours: 6));
              return DateTime(d.year, d.month, d.day).isAtSameMomentAs(todayDate);
            }).toList();
          } else if (_selectedFilter == TripFilter.tomorrow) {
            filteredByDate = allTrips.where((t) {
              if (t.departureTime == null) return false;
              final d = t.departureTime!.toUtc().add(const Duration(hours: 6));
              return DateTime(d.year, d.month, d.day).isAtSameMomentAs(tomorrowDate);
            }).toList();
          }

          // Apply search filter on top of date filter
          final trips = filteredByDate.where((trip) {
            if (_searchQuery.isEmpty) return true;
            final query = _searchQuery.toLowerCase().trim();
            final coach = (trip.coachCode ?? '').toLowerCase();
            final from = (trip.fromStation ?? '').toLowerCase();
            final to = (trip.toStation ?? '').toLowerCase();
            
            return coach.contains(query) || 
                   from.contains(query) || 
                   to.contains(query) ||
                   '$from $to'.contains(query) ||
                   '$from → $to'.contains(query) ||
                   '$from to $to'.contains(query);
          }).toList();

          final errorMessage = provider.errorMessage;

          if (allTrips.isEmpty && errorMessage != null) {
            return _buildErrorState(errorMessage);
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchStaffTrips(),
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: _buildProfileHeader(provider.currentUser),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TripHeaderDelegate(
                    height: allTrips.isNotEmpty ? 135 : 75,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(20, 15, 20, 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (!_isSearchVisible)
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Your Assigned Trips',
                                      style: GoogleFonts.inter(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ).animate().fadeIn(duration: 200.ms),
                                ),
                              Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  height: 50,
                                  margin: EdgeInsets.only(left: _isSearchVisible ? 0 : 16),
                                  child: Row(
                                    mainAxisAlignment: _isSearchVisible ? MainAxisAlignment.start : MainAxisAlignment.end,
                                    children: [
                                      if (_isSearchVisible) ...[
                                        const SizedBox(width: 15),
                                        const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                                        Expanded(
                                          child: TextField(
                                            controller: _searchController,
                                            focusNode: _searchFocusNode,
                                            textInputAction: TextInputAction.search,
                                            decoration: InputDecoration(
                                              hintText: 'Search coach or route...',
                                              hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
                                              border: InputBorder.none,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                                              suffixIcon: _searchQuery.isNotEmpty
                                                  ? IconButton(
                                                      icon: const Icon(Icons.cancel_rounded, color: Colors.grey, size: 20),
                                                      onPressed: () {
                                                        _searchController.clear();
                                                        HapticFeedback.lightImpact();
                                                      },
                                                    )
                                                  : null,
                                            ),
                                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                      IconButton(
                                        icon: Icon(
                                          _isSearchVisible ? Icons.close_rounded : Icons.search_rounded,
                                          color: AppColors.primary,
                                          size: 28,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            if (_isSearchVisible) {
                                              _isSearchVisible = false;
                                              _searchController.clear();
                                              _searchFocusNode.unfocus();
                                            } else {
                                              _isSearchVisible = true;
                                              _searchFocusNode.requestFocus();
                                            }
                                          });
                                          HapticFeedback.selectionClick();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (allTrips.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildFilterPill(
                                    label: 'All',
                                    count: countAll,
                                    filter: TripFilter.all,
                                    isSelected: _selectedFilter == TripFilter.all,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: _buildFilterPill(
                                    label: 'Today',
                                    count: countToday,
                                    filter: TripFilter.today,
                                    isSelected: _selectedFilter == TripFilter.today,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 4,
                                  child: _buildFilterPill(
                                    label: 'Tomorrow',
                                    count: countTomorrow,
                                    filter: TripFilter.tomorrow,
                                    isSelected: _selectedFilter == TripFilter.tomorrow,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (allTrips.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Colors.grey[600],
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Press & hold to view details',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 400.ms),
                    ),
                  ),
                if (trips.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyTripsState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                    sliver: SliverList(
                      key: ValueKey('trip_list_${_selectedFilter}'),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final trip = trips[index];
                          return RepaintBoundary(
                            key: ValueKey('trip_card_${trip.id}'),
                            child: _buildTripCard(trip)
                                .animate(key: ValueKey('anim_${trip.id}'))
                                .fadeIn(duration: 200.ms, delay: (index < 6 ? index * 50 : 0).ms)
                                .slideY(begin: 0.05, end: 0, duration: 300.ms),
                          );
                        },
                        childCount: trips.length,
                        addAutomaticKeepAlives: true,
                        addRepaintBoundaries: true,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 60, color: Color(0xFF2E7D32)),
            const SizedBox(height: 20),
            Text(
              'Sync Failed',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<TripProvider>().fetchStaffTrips(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFE6ECE5),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFFF5F5F5),
                      child: ClipOval(
                        child: (user?.profilePicUrl != null && user!.profilePicUrl!.isNotEmpty)
                            ? Image.network(
                                user.profilePicUrl!,
                                width: 64,
                                height: 64,
                                cacheWidth: 128,
                                cacheHeight: 128,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(user, size: 64, fontSize: 24),
                              )
                            : _buildAvatarFallback(user, size: 64, fontSize: 24),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        (user?.fullName ?? '').toUpperCase(),
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        (user?.username != null && user!.username.isNotEmpty)
                            ? '${user.username.toLowerCase()}'
                            : '',
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFFFEBEE)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildCompactBadge(
                icon: Icons.badge_rounded,
                label: 'EMP-ID: ${user?.erpId ?? "N/A"}',
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              _buildCompactBadge(
                icon: Icons.person,
                label: user?.role ?? "N/A",
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildFilterPill({
    required String label,
    required int count,
    required TripFilter filter,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = filter);
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppColors.primary,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (filter == TripFilter.today || filter == TripFilter.tomorrow)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              Text(
                '$label ($count)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildAssignmentStatus(IconData icon, String label, bool isAssigned) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isAssigned 
            ? const Color(0xFF4CAF50).withValues(alpha: 0.1) 
            : const Color(0xFF2E7D32).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isAssigned ? const Color(0xFF2E7D32) : const Color(0xFFC62828)),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: isAssigned ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            isAssigned ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 10,
            color: isAssigned ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBadge({required IconData icon, required String label, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTripCard(Trip trip) {
    final String timeStr = _formatDateTime(trip.departureTime);
    final String dateStr = _formatDate(trip.departureTime);

    return _HoldToConfirmTrip(
      onConfirm: () => _handleTripSelection(trip),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEBEDF0),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 1),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 85,
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('COACH', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black)),
                      const SizedBox(height: 1),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          (trip.coachCode ?? 'N/A').toUpperCase(),
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${trip.fromStation} ➔ ${trip.toStation}'.toUpperCase(),
                            style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 0.1),
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'VEHICLE: ${trip.vehicleNo != null && trip.vehicleNo!.isNotEmpty ? trip.vehicleNo!.toUpperCase().trim() : "NOT ASSIGNED"}',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[600]),
                          ),
                        ),
                        if (trip.vehicle?.manufacturer != null && trip.vehicle!.manufacturer!.isNotEmpty && trip.vehicle!.manufacturer!.toLowerCase() != 'null')
                          Text(
                            trip.vehicle!.manufacturer!.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildAssignmentStatus(Icons.person, 'Driver', trip.driver?.id != null),
                            const SizedBox(width: 6),
                            _buildAssignmentStatus(Icons.group_outlined, 'Helper', trip.helper?.id != null),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Divider(height: 1, color: Colors.white),
            ),
            Row(
              children: [
                Container(
                  width: 85,
                  padding: const EdgeInsets.only(bottom: 10),
                  child: const Icon(Icons.directions_bus_rounded, color: Color(0xFF2E7D32), size: 28),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 10, right: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            dateStr.toUpperCase(),
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            timeStr.toUpperCase(),
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTripsState() {
    String filterName = 'today';
    if (_selectedFilter == TripFilter.tomorrow) filterName = 'tomorrow';
    if (_selectedFilter == TripFilter.all) filterName = 'you';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ).animate().scale(delay: 100.ms, duration: 600.ms, curve: Curves.easeOutBack),
              
              // Animated Clouds from the image
              Positioned(
                left: 20,
                top: 40,
                child: Icon(Icons.cloud_rounded, color: AppColors.primary.withValues(alpha: 0.15), size: 30)
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .moveX(begin: -5, end: 5, duration: 2.seconds),
              ),
              Positioned(
                right: 15,
                bottom: 50,
                child: Icon(Icons.cloud_rounded, color: AppColors.primary.withValues(alpha: 0.15), size: 40)
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .moveX(begin: 5, end: -5, duration: 2.5.seconds),
              ),
              
              const Icon(
                Icons.directions_bus_rounded,
                size: 70,
                color: AppColors.primary,
              ).animate().shake(delay: 500.ms, duration: 500.ms),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            _searchQuery.isNotEmpty 
                ? 'No matches found'
                : 'No trips assigned for $filterName.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try searching with a different keyword.'
                : '',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(User? user, {double size = 100, double fontSize = 40}) {
    String initial = user != null && user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '';
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: fontSize,
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    height: 28,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 40,
                  width: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            ...List.generate(3, (index) => Container(
              margin: const EdgeInsets.only(bottom: 20),
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _TripHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _TripHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Colors.white,
      elevation: overlapsContent ? 3 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _TripHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

class _HoldToConfirmTrip extends StatefulWidget {
  final Widget child;
  final VoidCallback onConfirm;
  final BorderRadius borderRadius;

  const _HoldToConfirmTrip({
    required this.child,
    required this.onConfirm,
    required this.borderRadius,
  });

  @override
  State<_HoldToConfirmTrip> createState() => _HoldToConfirmTripState();
}

class _HoldToConfirmTripState extends State<_HoldToConfirmTrip> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reset();
        setState(() => _isHolding = false);
        HapticFeedback.heavyImpact();
        widget.onConfirm();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isHolding = true);
        _controller.forward();
        HapticFeedback.mediumImpact();
      },
      onTapUp: (_) {
        if (_controller.status != AnimationStatus.completed) {
          _controller.reverse();
        }
        setState(() => _isHolding = false);
      },
      onTapCancel: () {
        if (_controller.status != AnimationStatus.completed) {
          _controller.reverse();
        }
        setState(() => _isHolding = false);
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.only(bottom: 20, left: 2, right: 2),
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
                if (_controller.value > 0)
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.3 * _controller.value),
                    blurRadius: 20 * _controller.value,
                    spreadRadius: 4 * _controller.value,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: widget.borderRadius,
              child: Stack(
                children: [
                  widget.child,
                  if (_isHolding)
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 3 * _controller.value,
                          sigmaY: 3 * _controller.value,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.4 * _controller.value),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.touch_app_rounded,
                                  color: Color(0xFF2E7D32),
                                  size: 32,
                                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                                const SizedBox(height: 8),
                                Text(
                                  'OPENING TRIP',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    letterSpacing: 1.5,
                                  ),
                                ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_isHolding)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: _controller.value,
                        backgroundColor: Colors.black12,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                        minHeight: 8,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
