import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/models.dart';
import '../../../core/constants/app_colors.dart';
import 'reservation_details_screen.dart';








class VerificationSuccessScreen extends StatefulWidget {
  final List<Ticket> tickets;
  final bool isManualFlow;

  const VerificationSuccessScreen({
    super.key,
    required this.tickets,
    this.isManualFlow = false,
  });

  @override
  State<VerificationSuccessScreen> createState() =>
      _VerificationSuccessScreenState();
}

class _VerificationSuccessScreenState extends State<VerificationSuccessScreen> {
  Timer? _transitionTimer;

  @override
  void initState() {
    super.initState();
    _triggerSuccessFeedback();

    _transitionTimer = Timer(const Duration(milliseconds: 1500), _navigateToNextScreen);
  }

  @override
  void dispose() {
    _transitionTimer?.cancel(); 
    super.dispose();
  }

  Future<void> _triggerSuccessFeedback() async {

    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) await HapticFeedback.lightImpact();
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ReservationDetailsScreen(
          tickets: widget.tickets,
          isManualFlow: widget.isManualFlow,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeIn,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    if (widget.tickets.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Error: No ticket data found')),
      );
    }

    final List<String> sortedSeats = widget.tickets
        .map((t) => t.seatNo.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    sortedSeats.sort((a, b) => Ticket.naturalCompare(a, b));
    final String seatString = sortedSeats.join(', ');

    return PopScope(
      canPop: false, 
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [

            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withValues(alpha: 0.03),
                ),
              ).animate().scale(duration: 1200.ms, curve: Curves.easeOutCubic),
            ),
            
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSuccessAnimation(),
                  const SizedBox(height: 45),

                  Text(
                    'VERIFICATION SUCCESSFUL',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.success,
                      letterSpacing: 4,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                      
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      widget.tickets.length > 1 ? 'SEATS: $seatString' : 'SEAT: $seatString',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -1.2,
                        height: 1.1,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms)
                      .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
                      
                  const SizedBox(height: 10),
                  
                  Text(
                    'Boarding status updated successfully',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                  
                  const SizedBox(height: 70),

                  SizedBox(
                    width: 160,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const LinearProgressIndicator(
                        minHeight: 6,
                        backgroundColor: Color(0xFFF0F0F0),
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 800.ms)
                      .scaleX(begin: 0, end: 1, duration: 800.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [

        Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.08),
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.25, 1.25),
              duration: 1200.ms,
              curve: Curves.easeInOut,
            )
            .fadeOut(),

        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.12),
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

        Container(
          width: 95,
          height: 95,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success,
            boxShadow: [
              BoxShadow(
                color: Color(0x404CAF50),
                blurRadius: 30,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 58,
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
      ],
    );
  }
}
