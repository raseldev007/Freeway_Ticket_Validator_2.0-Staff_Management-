import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:freeway_ticket_validator/core/widgets/otp_pin_field.dart';
import 'package:freeway_ticket_validator/core/providers/trip_provider.dart';
import 'package:freeway_ticket_validator/core/constants/app_colors.dart';
import 'package:freeway_ticket_validator/features/dashboard/screens/staff_profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpRequested = false;
  Timer? _resendTimer;
  int _resendCountdown = 30;
  bool _canResend = false;
  bool _isMobileValid = false;
  bool _isOtpValid = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _checkForUpdate();
    _mobileController.addListener(_validateMobile);
    _otpController.addListener(_validateOtp);
  }

  Future<void> _loadAppVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = 'v${packageInfo.version} • Freeway Systems';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _appVersion = 'Freeway Systems';
        });
      }
    }
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

  void _validateMobile() {
    setState(() {
      _isMobileValid = _mobileController.text.length >= 11;
    });
  }

  void _validateOtp() {
    setState(() {
      _isOtpValid = _otpController.text.length == 5;
    });
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleRequestOtp() async {
    if (_mobileController.text.length < 11) {
      if (!mounted) return;
      _showError('Please enter a valid mobile number');
      return;
    }
    final success = await context.read<TripProvider>().requestOtp(
          _mobileController.text,
        );
    if (success) {
      HapticFeedback.mediumImpact();
      setState(() => _otpRequested = true);
      if (mounted) {
        _startResendTimer();
        _showSuccess(
          context.read<TripProvider>().otpSentMessage ??
              'OTP sent successfully',
        );
      }
    } else {
      HapticFeedback.vibrate();
      if (mounted) {
        _showError(
          context.read<TripProvider>().errorMessage ?? 'Failed to send OTP',
        );
      }
    }
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 180;
      _canResend = false;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      }
    });
  }

  Future<void> _handleLogin() async {
    if (_resendCountdown == 0) {
      _showError('OTP has expired. Please request a new one.');
      return;
    }
    if (_otpController.text.length < 5) {
      _showError('Please enter a valid 5-digit OTP');
      return;
    }
    final success = await context.read<TripProvider>().loginWithOtp(
          _mobileController.text,
          _otpController.text,
        );
    if (success) {
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      HapticFeedback.lightImpact();
      if (mounted) {
        // Trigger trip fetching early to show shimmer immediately on the next screen
        context.read<TripProvider>().fetchStaffTrips(showLoading: true);
        
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const StaffProfileScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    } else {
      HapticFeedback.vibrate();
      if (mounted) {
        _showError(
          context.read<TripProvider>().errorMessage ??
              'Account verification failed',
        );
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<TripProvider>().isLoading;

    String formatTime(int seconds) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF8F9FA),
                    Colors.white,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  SizedBox(
                    height: 160,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  )
                      .animate()
                      .scale(duration: 400.ms, curve: Curves.easeOutBack)
                      .fadeIn(duration: 400.ms),
                  const SizedBox(height: 40),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Staff Login',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          _otpRequested
                              ? 'Please enter the 5-digit verification OTP'
                              : 'Enter your mobile number to receive an authentication OTP',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Mobile Number'),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _mobileController,
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              enabled: !isLoading,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(11),
                              ],
                              onChanged: (value) {
                                if (_otpRequested) {
                                  setState(() {
                                    _otpRequested = false;
                                    _otpController.clear();
                                    _resendTimer?.cancel();
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                hintText: '017********',
                                hintStyle: GoogleFonts.inter(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixText: '+88 ',
                                prefixStyle: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                prefixIcon: const Icon(
                                  Icons.phone_android_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color: Colors.grey[100]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color: Colors.grey[100]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                              ),
                            ),
                            if (_otpRequested) ...[
                              const SizedBox(height: 24),
                              _buildLabel('OTP Verification'),
                              const SizedBox(height: 12),
                              OtpPinField(
                                length: 5,
                                autofocus: true,
                                controller: _otpController,
                                onCompleted: (value) => _handleLogin(),
                              ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 62,
                        child: ElevatedButton(
                          onPressed: (isLoading ||
                                  (!_otpRequested && !_isMobileValid) ||
                                  (_otpRequested && !_isOtpValid))
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  _otpRequested
                                      ? _handleLogin()
                                      : _handleRequestOtp();
                                },
                          style: ElevatedButton.styleFrom(
                            elevation:
                                (_otpRequested ? _isOtpValid : _isMobileValid)
                                    ? 8
                                    : 0,
                            shadowColor:
                                AppColors.primary.withValues(alpha: 0.3),
                            backgroundColor:
                                (_otpRequested ? _isOtpValid : _isMobileValid)
                                    ? AppColors.primary
                                    : Colors.grey[300],
                            foregroundColor:
                                (_otpRequested ? _isOtpValid : _isMobileValid)
                                    ? Colors.white
                                    : Colors.grey[600],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: isLoading
                              ? SizedBox(
                                  height: 62,
                                  width: double.infinity,
                                  child: Shimmer.fromColors(
                                    baseColor: Colors.white.withValues(alpha: 0.3),
                                    highlightColor: Colors.white.withValues(alpha: 0.6),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                )
                              : Text(
                                  _otpRequested ? 'SIGN IN' : 'GET OTP',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),
                      if (_otpRequested) ...[
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _canResend
                                  ? 'Didn\'t receive OTP? '
                                  : 'OTP expires in ',
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (!_canResend)
                              Text(
                                formatTime(_resendCountdown),
                                style: GoogleFonts.inter(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            if (_canResend)
                              TextButton(
                                onPressed: isLoading ? null : _handleRequestOtp,
                                style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Resend Now',
                                  style: GoogleFonts.inter(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    _appVersion.isEmpty ? 'Freeway Systems' : _appVersion,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withValues(alpha: 0.5),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

