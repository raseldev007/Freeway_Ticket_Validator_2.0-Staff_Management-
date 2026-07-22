import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';

class PassengerListScreen extends StatefulWidget {
  const PassengerListScreen({super.key});

  @override
  State<PassengerListScreen> createState() => _PassengerListScreenState();
}

class _PassengerListScreenState extends State<PassengerListScreen> {
  String _filterStatus = 'All';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripProvider>();
    final trip = provider.currentTrip;
    final List<Ticket> rawTickets = trip?.tickets ?? [];

    if (provider.isLoading || provider.isRefreshing) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context),
        body: _buildShimmerLoading(),
      );
    }
    final List<Ticket> allTickets = [];

    for (var ticket in rawTickets) {
      final seatParts = ticket.seatNo
          .split(RegExp(r'[,+]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (seatParts.length > 1) {
        for (var seat in seatParts) {
          allTickets.add(ticket.copyWith(seatNo: seat));
        }
      } else {
        allTickets.add(ticket);
      }
    }

    allTickets.sort((a, b) => Ticket.naturalCompare(a.seatNo, b.seatNo));

    List<Ticket> displayedTickets;
    if (_filterStatus == 'Verified') {
      displayedTickets = allTickets.where((t) => t.isVerified).toList();
    } else if (_filterStatus == 'Pending') {
      displayedTickets = allTickets.where((t) => !t.isVerified).toList();
    } else {
      displayedTickets = allTickets;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: () async {
          final provider = context.read<TripProvider>();
          if (provider.currentTrip != null) {
            await provider.fetchTrip(provider.currentTrip!.id);
          }
        },
        child: allTickets.isEmpty
            ? _buildModernEmptyState(context)
            : Column(
          children: [
            _buildPremiumSummary(context, allTickets),
            Expanded(
              child: displayedTickets.isEmpty
                  ? _buildEmptyFilterState()
                  : ListView.separated(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 40.h),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: displayedTickets.length,
                addAutomaticKeepAlives: true,
                addRepaintBoundaries: true,
                separatorBuilder: (context, index) =>
                SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final item = displayedTickets[index];
                  return RepaintBoundary(
                    key: ValueKey('ticket_${item.pnr}_${item.seatNo}'),
                    child: _buildPremiumPassengerCard(context, item)
                        .animate(key: ValueKey('anim_${item.pnr}_${item.seatNo}'))
                        .fadeIn(duration: 200.ms, delay: (index < 10 ? index * 30 : 0).ms)
                        .slideY(begin: 0.04, end: 0, duration: 300.ms),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumSummary(BuildContext context, List<Ticket> tickets) {
    final verifiedCount = tickets.where((t) => t.isVerified).length;
    final pendingCount = tickets.length - verifiedCount;

    return Padding(
      padding: EdgeInsets.all(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: Colors.grey[100]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildSummaryItem(
                'TOTAL',
                tickets.length.toString(),
                AppColors.textPrimary,
                'All',
              ),
            ),
            _buildDivider(),
            Expanded(
              child: _buildSummaryItem(
                'VERIFIED',
                verifiedCount.toString(),
                AppColors.success,
                'Verified',
              ),
            ),
            _buildDivider(),
            Expanded(
              child: _buildSummaryItem(
                'PENDING',
                pendingCount.toString(),
                AppColors.warning,
                'Pending',
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 600.ms)
          .scale(begin: const Offset(0.95, 0.95)),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, Color color, String filterValue) {
    final isSelected = _filterStatus == filterValue;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filterStatus = filterValue;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            if (isSelected) ...[
              SizedBox(height: 4.h),
              Container(
                width: 16.w,
                height: 3.h,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 30, width: 1, color: Colors.grey[200]);
  }

  Widget _buildEmptyFilterState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_list_off, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No $_filterStatus passengers",
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumPassengerCard(BuildContext context, Ticket ticket) {
    final trip = context.read<TripProvider>().currentTrip;

    final from = trip?.fromStation ?? 'N/A';
    final to = trip?.toStation ?? 'N/A';

    final station = ticket.boardingPoint ?? trip?.busStation ?? 'N/A';
    final dropping = ticket.droppingPoint ?? 'N/A';

    String shorten(String s) {
      return s.toUpperCase();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEDF0),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15.r,
            spreadRadius: 0,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ticket.passengerName.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                constraints: BoxConstraints(
                  minWidth: 48.w,
                  minHeight: 48.h,
                ),
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEEAEA),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'SEAT',
                      style: GoogleFonts.inter(
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      ticket.seatNo,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PNR: ${ticket.pnr.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${shorten(from)} -> ${shorten(to)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'BOARDING: ${shorten(station)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'DROPPING: ${shorten(dropping)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: ticket.isVerified ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          ticket.isVerified ? Icons.verified_rounded : Icons.pending_actions_rounded,
                          size: 12.sp,
                          color: ticket.isVerified ? const Color(0xFF2E7D32) : const Color(0xFFF9A825),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          ticket.isVerified ? 'VERIFIED' : 'PENDING',
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w800,
                            color: ticket.isVerified ? const Color(0xFF2E7D32) : const Color(0xFFF9A825),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Passenger List',
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18.sp),
      ),
      foregroundColor: AppColors.textPrimary,
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 22,
          color: AppColors.primary,
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: 5,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_search_rounded,
                size: 64,
                color: Colors.grey[300],
              ),
            ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              'No Passengers Yet',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find any passenger records for this trip.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 400.ms),
    );
  }
}
