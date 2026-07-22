import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/trip_provider.dart';
import '../../dashboard/screens/staff_profile_screen.dart';

class LoginSuccessScreen extends StatefulWidget {
  final String staffName;

  const LoginSuccessScreen({
    super.key,
    required this.staffName,
  });

  @override
  State<LoginSuccessScreen> createState() => _LoginSuccessScreenState();
}

class _LoginSuccessScreenState extends State<LoginSuccessScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _startSuccessSequence();
  }

  void _startSuccessSequence() {
    HapticFeedback.heavyImpact();

    Future.microtask(() {
      if (mounted) {
        context.read<TripProvider>().fetchStaffTrips();
      }
    });

    _navigationTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        _navigateToDashboard();
      }
    });
  }

  void _navigateToDashboard() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const StaffProfileScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withValues(alpha: 0.03),
                ),
              ).animate().scale(duration: 1000.ms, curve: Curves.easeOut),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success.withValues(alpha: 0.08),
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.3, 1.3),
                            duration: 1500.ms,
                            curve: Curves.easeInOut,
                          )
                          .fadeOut(),
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success.withValues(alpha: 0.15),
                        ),
                      ).animate().scale(
                            duration: 400.ms,
                            curve: Curves.easeOutBack,
                          ),
                      Container(
                        width: 90,
                        height: 90,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x404CAF50),
                              blurRadius: 24,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 50,
                        ),
                      ).animate().scale(
                            duration: 500.ms,
                            curve: Curves.elasticOut,
                          ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'SUCCESSFULLY VERIFIED',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                      letterSpacing: 2,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        Text(
                          'Welcome,',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.staffName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: 180,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            minHeight: 6,
                            backgroundColor: const Color(0xFFF0F0F0),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(AppColors.success),
                          ).animate().shimmer(
                            duration: 1500.ms,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ).animate().scaleX(begin: 0, end: 1, duration: 1800.ms),
                        const SizedBox(height: 16),
                        Text(
                          'Live Data Sync in Progress...',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ).animate().fadeIn(delay: 800.ms),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
