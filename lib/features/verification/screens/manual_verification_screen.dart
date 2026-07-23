import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:freeway_ticket_validator/core/providers/trip_provider.dart';
import 'package:freeway_ticket_validator/core/constants/app_colors.dart';
import 'package:freeway_ticket_validator/features/verification/screens/verification_success_screen.dart';
import 'package:freeway_ticket_validator/core/widgets/otp_pin_field.dart';

class ManualVerificationScreen extends StatefulWidget {
  final String? initialPnr;
  const ManualVerificationScreen({super.key, this.initialPnr});

  @override
  State<ManualVerificationScreen> createState() =>
      _ManualVerificationScreenState();
}

class _ManualVerificationScreenState extends State<ManualVerificationScreen> {
  late final TextEditingController _pnrController;
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  final ValueNotifier<bool> _isFormValid = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _pnrController = TextEditingController(text: widget.initialPnr);

    _pnrController.addListener(_validateForm);
    _pinController.addListener(_validateForm);

    _validateForm();
  }

  void _validateForm() {
    final pnrText = _pnrController.text.trim();

    if (pnrText.length == 9 &&
        _pinController.text.isEmpty &&
        !_pinFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pinController.text.isEmpty) {
          _pinFocusNode.requestFocus();
        }
      });
    }

    final isValid =
        pnrText.length >= 8 && _pinController.text.trim().length == 4;
    if (_isFormValid.value != isValid) {
      _isFormValid.value = isValid;
    }
  }

  @override
  void dispose() {
    _pnrController.dispose();
    _pinController.dispose();
    _pinFocusNode.dispose();
    _isFormValid.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final provider = context.read<TripProvider>();
    if (provider.currentTrip == null) {
      _showResultDialog(
        false,
        message: 'Please select a Trip first (Trip ID required).',
      );
      return;
    }

    final pnr = _pnrController.text.trim();
    final pin = _pinController.text.trim();

    if (pnr.isEmpty || pin.isEmpty) {
      _showSnack('Please enter both PNR and PIN', Colors.amber[800]!);
      return;
    }

    if (pin.length != 4) {
      _showSnack('PIN must be exactly 4 digits', Colors.amber[800]!);
      return;
    }

    final result = await provider.verifyTicket(pnr, pin);

    if (mounted) {
      if (result != null && !provider.isLastVerificationAlreadyVerified) {
        HapticFeedback.heavyImpact();
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationSuccessScreen(
              tickets: result,
              isManualFlow: true,
            ),
          ),
        );
      } else {
        HapticFeedback.vibrate();
        final error = provider.errorMessage ?? 'Verification Failed';

        String title = 'Invalid Ticket';
        if (error.contains('Internet') || error.contains('Socket')) {
          title = 'Network Error';
        } else if (error.contains('Trip')) {
          title = 'Trip Mismatch';
        }
        
        _showResultDialog(false, title: title, message: error);
      }
    }
  }

  Future<void> _handleResend() async {
    final provider = context.read<TripProvider>();

    if (provider.currentTrip == null) {
      _showResultDialog(
        false,
        message: 'Please select a Trip first to resend PIN.',
      );
      return;
    }

    final pnr = _pnrController.text.trim();

    if (pnr.isEmpty) {
      _showSnack('Please enter PNR first', Colors.amber[800]!);
      return;
    }

    final success = await provider.resendPin(pnr);

    if (!mounted) return;

    if (success) {
      HapticFeedback.mediumImpact();
      _showSnack('PIN resent successfully', AppColors.success);
    } else {
      HapticFeedback.vibrate();
      final error = provider.errorMessage ?? 'Failed to resend PIN';

      if (error == 'PNR & Trip Mismatch') {
        _showResultDialog(false,
            message:
                'PNR & Trip Mismatch! This PNR does not belong to the selected Trip.');
      } else {
        _showSnack(error, AppColors.error);
      }
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showResultDialog(bool success, {String? title, String? message}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: 300.ms,
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (success ? AppColors.success : AppColors.error)
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      success
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: success ? AppColors.success : AppColors.error,
                      size: 64,
                    ),
                  ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 24),
                  Text(
                    title ?? (success ? 'Ticket Verified' : 'Invalid Ticket'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message ??
                        (success
                            ? 'The passenger is cleared to board.'
                            : 'Please check the details and try again.'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color:
                                  success ? AppColors.success : AppColors.error,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'OK',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      success ? AppColors.success : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _pnrController.clear();
                            _pinController.clear();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                success ? AppColors.success : AppColors.error,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Verify Next',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<TripProvider>().isLoading;

    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: _buildShimmerLoading(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Verify Ticket'),
            const SizedBox(height: 20),
            _buildInputLabel('PNR'),
            _buildInputField(
              'Enter PNR',
              _pnrController,
              Icons.tag,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
            ),
            const SizedBox(height: 20),
            _buildInputLabel(
              'Secret PIN',
              trailing: InkWell(
                onTap: _handleResend,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.replay_rounded,
                        size: 13,
                        color: const Color(0xFF2D2F33),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'RESEND PIN',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2D2F33),
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _pnrController,
              builder: (context, value, child) {
                return OtpPinField(
                  length: 4,
                  controller: _pinController,
                  isObscure: true,
                  enabled: value.text.trim().length >= 9,
                  firstFocusNode: _pinFocusNode,
                );
              },
            ),
            const SizedBox(height: 24),
            ValueListenableBuilder<bool>(
              valueListenable: _isFormValid,
              builder: (context, isValid, child) {
                return _buildActionButton(
                  'Verify',
                  (!isValid || isLoading) ? null : _handleVerify,
                  isLoading,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Manual Verification',
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 20,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 15,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 58,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 15,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 58,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 58,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildInputLabel(String label, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4, right: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2D2F33),
              letterSpacing: 1.1,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildInputField(
    String hint,
    TextEditingController controller,
    IconData icon, {
    bool isObscure = false,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool autofocus = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        maxLength: maxLength,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        autofocus: autofocus,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          border: InputBorder.none,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    VoidCallback? onPressed,
    bool loading, {
    bool isSecondary = false,
  }) {
    final bool isDisabled = onPressed == null && !loading;

    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        boxShadow: isDisabled || isSecondary
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: onPressed != null
            ? () {
                HapticFeedback.selectionClick();
                onPressed();
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled
              ? Colors.grey[300]
              : (isSecondary ? Colors.grey[100] : AppColors.primary),
          foregroundColor: isDisabled
              ? Colors.grey[500]
              : (isSecondary ? AppColors.textPrimary : Colors.white),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSecondary ? Icons.close_rounded : Icons.verified_user_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}



