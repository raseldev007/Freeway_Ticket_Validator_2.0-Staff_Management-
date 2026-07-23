import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/trip_provider.dart';
import 'qr_verification_screen.dart';

class ReservationDetailsScreen extends StatelessWidget {
  final List<Ticket> tickets;
  final bool isManualFlow;

  const ReservationDetailsScreen({
    super.key,
    required this.tickets,
    this.isManualFlow = false,
  });

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No ticket data found.')),
      );
    }

    final trip = context.read<TripProvider>().currentTrip;
    final tripId = trip?.id ?? 'N/A';

    final firstTicket = tickets.first;
    final toStation = firstTicket.droppingPoint ??
        firstTicket.destination ??
        trip?.toStation ??
        'Unknown';
    final busStation =
        firstTicket.boardingPoint ?? trip?.busStation ?? 'Unknown';

    final List<String> sortedSeats = [];
    for (var t in tickets) {
      sortedSeats.addAll(t.seatNo.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
    }
    sortedSeats.sort((a, b) => Ticket.naturalCompare(a, b));
    
    final String pnr = tickets.isNotEmpty ? tickets.first.pnr : 'N/A';
    
    const Color primaryRed = Color(0xFFCD2026);
    const Color lightRedBg = Color(0xFFFFF2F2);
    const Color routeCardBg = Color(0xFFF0F1F3);

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 70.w,
        leading: Padding(
          padding: EdgeInsets.only(left: 15.w),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 40.w,
                width: 40.w,
                decoration: const BoxDecoration(
                  color: lightRedBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: primaryRed,
                  size: 18.sp,
                ),
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Reservation Details',
          style: GoogleFonts.inter(
            color: primaryRed,
            fontWeight: FontWeight.w700,
            fontSize: 20.sp,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 15.w),
            child: Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 40.w,
                  width: 40.w,
                  decoration: BoxDecoration(
                    border: Border.all(color: primaryRed.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.exit_to_app_rounded,
                    color: primaryRed,
                    size: 20.sp,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: lightRedBg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: primaryRed.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    height: 56.w,
                    width: 56.w,
                    decoration: const BoxDecoration(
                      color: primaryRed,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.confirmation_number_rounded,
                        color: Colors.white, size: 26.sp),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'PNR : $pnr',
                                style: GoogleFonts.inter(
                                  color: primaryRed,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Icon(Icons.verified,
                                color: const Color(0xFF4CAF50), size: 20.sp),
                          ],
                        ),
                        Text(
                          'Trip ID: $tripId',
                          style: GoogleFonts.inter(
                            color: Colors.black45,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            //  Passenger & Seats Card
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: routeCardBg,
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.personal_injury_sharp,
                              color: primaryRed, size: 26.sp),
                          SizedBox(height: 8.h),
                          Text(
                            'PASSENGER',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.black38,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              firstTicket.passengerName.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 12.w),
                      width: 1.2.w,
                      color: Colors.black.withValues(alpha: 0.2),
                    ),

                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.airline_seat_recline_extra_rounded,
                              color: primaryRed, size: 26.sp),
                          SizedBox(height: 8.h),
                          Text(
                            'SEAT',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.black38,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0; i < sortedSeats.length; i += 3)
                                Padding(
                                  padding: EdgeInsets.only(bottom: 6.h),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (int j = i; j < i + 3 && j < sortedSeats.length; j++)
                                        Padding(
                                          padding: EdgeInsets.only(right: 6.w),
                                          child: Text(
                                            "${sortedSeats[j]}${j < sortedSeats.length - 1 ? ',' : ''}",
                                            style: GoogleFonts.inter(
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.w900,
                                              color: primaryRed,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.h),

            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: routeCardBg,
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Column(
                children: [
                  _buildRouteItem(
                    label: 'BOARDING POINT',
                    value: busStation,
                    isStart: true,
                    primaryRed: primaryRed,
                  ),
                  _buildRouteItem(
                    label: 'DROP-OFF POINT',
                    value: toStation,
                    isStart: false,
                    primaryRed: primaryRed,
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56.h,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primaryRed, width: 1.5.w),
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.west_rounded, color: primaryRed, size: 18.sp),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Go Back',
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  color: primaryRed,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: SizedBox(
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isManualFlow) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const QrVerificationScreen()),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.playlist_add_check_rounded, size: 24.sp),
                          SizedBox(width: 4.w),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                isManualFlow ? 'Verify Next' : 'Scan Next',
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
      ),
    );
  }

  Widget _buildRouteItem({
    required String label,
    required String value,
    required bool isStart,
    required Color primaryRed,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: primaryRed,
                size: 18.sp,
              ),
            ),
            if (isStart)
              Container(
                width: 2.w,
                height: 30.h,
                margin: EdgeInsets.symmetric(vertical: 2.h),
                child: CustomPaint(
                  painter: DottedLinePainter(color: Colors.black12),
                ),
              ),
          ],
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4.h),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black38,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (isStart) SizedBox(height: 12.h),
            ],
          ),
        ),
      ],
    );
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;
  DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 3.h, dashSpace = 3.h, startY = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.w
      ..strokeCap = StrokeCap.round;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
