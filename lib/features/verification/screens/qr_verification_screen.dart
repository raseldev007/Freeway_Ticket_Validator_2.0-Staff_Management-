import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/constants/app_colors.dart';
import 'verification_success_screen.dart';
import '../../../core/models/models.dart';
import '../../dashboard/screens/dashboard_screen.dart';

class QrVerificationScreen extends StatefulWidget {
  const QrVerificationScreen({super.key});
  @override
  State<QrVerificationScreen> createState() => _QrVerificationScreenState();
}

class _QrVerificationScreenState extends State<QrVerificationScreen>
    with WidgetsBindingObserver {
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _isProcessing = false;
  Timer? _inactivityTimer;
  bool _isCameraPaused = false;
  bool _isCameraRunning = false;
  bool _isDisposed = false;
  Future<void>? _cameraLock;
  static const Duration _inactivityTimeout = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
    _resetInactivityTimer();
  }

  Future<void> _checkPermission() async {
    final status = await ph.Permission.camera.status;
    if (status.isDenied) {
      final result = await ph.Permission.camera.request();
      if (result.isPermanentlyDenied) {
        if (mounted) _showPermissionDialog();
      } else if (result.isGranted) {
        _resumeCamera();
      }
    } else if (status.isGranted) {
      _resumeCamera();
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    if (_isCameraPaused) {
      _resumeCamera();
    }
    _inactivityTimer = Timer(_inactivityTimeout, _pauseCameraDueToInactivity);
  }

  Future<void> _pauseCameraDueToInactivity() async {
    if (!mounted || _isDisposed || _isProcessing || !_isCameraRunning) return;

    final completer = Completer<void>();
    final previous = _cameraLock;
    _cameraLock = completer.future;
    await previous?.catchError((_) {});

    if (_isDisposed || !mounted || !cameraController.value.isRunning) {
      completer.complete();
      return;
    }

    try {
      _isCameraRunning = false;
      await cameraController.stop();
      if (mounted && !_isDisposed) {
        setState(() => _isCameraPaused = true);
      }
    } catch (e) {
      debugPrint('Error stopping camera $e');
    } finally {
      completer.complete();
    }
  }

  Future<void> _resumeCamera() async {
    if (!mounted || _isDisposed) return;
    
    final completer = Completer<void>();
    final previous = _cameraLock;
    _cameraLock = completer.future;
    await previous?.catchError((_) {});

    if (_isDisposed || !mounted || cameraController.value.isRunning) {
      completer.complete();
      return;
    }

    try {
      await cameraController.start();
      _isCameraRunning = true;
      if (mounted && !_isDisposed) {
        setState(() => _isCameraPaused = false);
      }
    } catch (e) {
      if (e.toString().contains('controllerInitializing')) {
        _isCameraRunning = true;
      } else {
        debugPrint('Error starting camera $e');
      }
    } finally {
      completer.complete();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission'),
        content: const Text(
            'Camera access is required to scan QR codes. Please enable it in settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ph.openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || _isDisposed) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _pauseCameraForLifecycle();
    } else if (state == AppLifecycleState.resumed) {
      if (!_isCameraPaused) {
        _resumeCamera();
      }
    }
  }

  Future<void> _pauseCameraForLifecycle() async {
    final completer = Completer<void>();
    final previous = _cameraLock;
    _cameraLock = completer.future;
    await previous?.catchError((_) {});

    try {
      if (cameraController.value.isRunning || _isCameraRunning) {
        _isCameraRunning = false;
        await cameraController.stop();
      }
    } catch (e) {
      debugPrint('Error stopping camera on lifecycle change $e');
    } finally {
      completer.complete();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    _isCameraRunning = false;
    try {
      cameraController.dispose();
    } catch (e) {
      debugPrint('Error disposing camera $e');
    }
    super.dispose();
  }

  Future<void> _handleScannedCode(String code) async {
    _resetInactivityTimer();
    if (_isProcessing || code.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isProcessing = true;
    });
    if (!mounted) return;
    try {
      final tripProvider = context.read<TripProvider>();
      String? encryptedText;
      String? pnr;
      String? pin;
      String? operation;
      String? tripId;
      String normalized = code
          .trim()
          .replaceAll('“', '"')
          .replaceAll('”', '"')
          .replaceAll('‘', "'")
          .replaceAll('’', "'");

      if (normalized.startsWith('{') || normalized.startsWith('[')) {
        try {
          final dynamic decoded = jsonDecode(normalized);
          final Map<String, dynamic> jsonData = (decoded is List)
              ? (decoded.isNotEmpty ? decoded.first : {})
              : decoded;
          String? val(dynamic v) => (v?.toString().trim().isNotEmpty ?? false)
              ? v.toString().trim()
              : null;
          encryptedText = val(jsonData['encryptedText'] ??
              jsonData['encrypted_text'] ??
              jsonData['data']);
          pnr = val(jsonData['pnr'] ??
              jsonData['PNR'] ??
              jsonData['ticket_no'] ??
              jsonData['ticketNo']);
          pin =
              val(jsonData['pin'] ?? jsonData['PIN'] ?? jsonData['secret_pin']);
          operation = val(jsonData['operation'] ?? jsonData['op']);
          tripId = val(
              jsonData['tripId'] ?? jsonData['trip_id'] ?? jsonData['trip']);
          if (encryptedText == null && pnr == null) {
            encryptedText = normalized;
          }
        } catch (e) {
          encryptedText = normalized;
        }
      } else {
        if (normalized.contains('==') || normalized.length > 25) {
          encryptedText = normalized;
        } else {
          pnr = normalized;
        }
      }

      final result = await tripProvider.verifyTicket(
        pnr,
        pin,
        encryptedText: encryptedText,
        operation: operation,
        tripId: tripId,
      );
      _handleVerificationResult(result, tripProvider);
    } catch (e) {
      _showResultDialog(false,
          message: e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _handleVerificationResult(dynamic result, TripProvider tripProvider) {
    if (!mounted) return;
    if (result != null && !tripProvider.isLastVerificationAlreadyVerified) {
      HapticFeedback.heavyImpact();
      List<Ticket> verifiedTickets = (result is List<Ticket>)
          ? result
          : (result is Ticket ? [result] : []);
      if (verifiedTickets.isNotEmpty) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => VerificationSuccessScreen(
                      tickets: verifiedTickets,
                      isManualFlow: false,
                    )));
        return;
      }
    }
    HapticFeedback.vibrate();
    _showResultDialog(false,
        message: tripProvider.errorMessage ?? 'Verification failed');
  }

  void _showResultDialog(bool success, {String? message}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      transitionDuration: 300.ms,
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(32)),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                          success
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: success ? AppColors.success : AppColors.error,
                          size: 64)
                      .animate()
                      .scale(),
                  const SizedBox(height: 24),
                  Text(success ? 'Verified' : 'Failed',
                      style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color:
                              success ? AppColors.success : AppColors.error)),
                  const SizedBox(height: 8),
                  Text(message ?? '',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pop();
                        setState(() => _isProcessing = false);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              success ? AppColors.success : AppColors.error,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(success ? Icons.refresh_rounded : Icons.replay_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Text('Try Again',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      } else {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const DashboardScreen()),
                            (route) => false);
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.home_rounded, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Back to Home',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                color: AppColors.primary)),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _resetInactivityTimer,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
            title: Text(
              'QR Verification',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            foregroundColor: Colors.white,
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const DashboardScreen()),
                    );
                  }
                })),
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            MobileScanner(
                controller: cameraController,
                onDetect: (capture) {
                  for (final barcode in capture.barcodes) {
                    if (barcode.rawValue != null) {
                      _handleScannedCode(barcode.rawValue!);
                      break;
                    }
                  }
                }),
            if (_isProcessing)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Shimmer.fromColors(
                              baseColor: Colors.grey[850]!,
                              highlightColor: Colors.grey[700]!,
                              period: const Duration(milliseconds: 1500),
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: 180,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Processing Ticket...',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ).animate().fadeIn(),
                            const SizedBox(height: 8),
                            Text(
                              'Please wait a moment',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ).animate().fadeIn(),
                          ],
                        ),
                      ).animate().scale(duration: 200.ms, curve: Curves.easeOut),
                    ),
                  ),
                ),
              ),
            if (_isCameraPaused)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.8),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pause_circle_outline,
                            color: Colors.white, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'Camera paused due to inactivity',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _resumeCamera,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.play_arrow_rounded, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Resume Camera',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned.fill(
                child: Container(
                    decoration: const ShapeDecoration(
                        shape: _ScannerOverlayShape(
                            borderColor: AppColors.primary, cutOutSize: 280)))),
            Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Center(
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(30)),
                        child: Text(
                            _isProcessing
                                ? 'Processing...'
                                : 'Scan Passenger QR Code',
                            style: GoogleFonts.inter(
                                color: Colors.white, 
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                            ))))),
            Positioned(
                top: 100,
                right: 20,
                child: Column(children: [
                  _buildToolCircle(
                      icon: Icons.flash_on_rounded,
                      onPressed: () => cameraController.toggleTorch()),
                  const SizedBox(height: 16),
                  _buildToolCircle(
                      icon: Icons.flip_camera_ios_rounded,
                      onPressed: () => cameraController.switchCamera())
                ])),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCircle(
          {required IconData icon, required VoidCallback onPressed}) =>
      GestureDetector(
          onTap: onPressed,
          child: Container(
              padding: const EdgeInsets.all(12),
              decoration:
                  BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 24)));
}

class _ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double cutOutSize;
  const _ScannerOverlayShape(
      {required this.borderColor, this.cutOutSize = 250});
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final Path path = Path()..addRect(rect);
    final Rect cutOutRect = Rect.fromCenter(
        center: rect.center, width: cutOutSize, height: cutOutSize);
    return Path.combine(
        PathOperation.difference,
        path,
        Path()
          ..addRRect(
              RRect.fromRectAndRadius(cutOutRect, const Radius.circular(30))));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final Paint paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    final double midX = rect.center.dx;
    final double midY = rect.center.dy;
    final double halfSize = cutOutSize / 2;
    final Path path = Path();
    path.moveTo(midX - halfSize, midY - halfSize + 40);
    path.lineTo(midX - halfSize, midY - halfSize + 20);
    path.arcToPoint(Offset(midX - halfSize + 20, midY - halfSize),
        radius: const Radius.circular(20));
    path.lineTo(midX - halfSize + 40, midY - halfSize);
    path.moveTo(midX + halfSize - 40, midY - halfSize);
    path.lineTo(midX + halfSize - 20, midY - halfSize);
    path.arcToPoint(Offset(midX + halfSize, midY - halfSize + 20),
        radius: const Radius.circular(20));
    path.lineTo(midX + halfSize, midY - halfSize + 40);
    path.moveTo(midX + halfSize, midY + halfSize - 40);
    path.lineTo(midX + halfSize, midY + halfSize - 20);
    path.arcToPoint(Offset(midX + halfSize - 20, midY + halfSize),
        radius: const Radius.circular(20), clockwise: true);
    path.lineTo(midX + halfSize - 40, midY + halfSize);
    path.moveTo(midX - halfSize + 40, midY + halfSize);
    path.lineTo(midX - halfSize + 20, midY + halfSize);
    path.arcToPoint(Offset(midX - halfSize, midY + halfSize - 20),
        radius: const Radius.circular(20), clockwise: true);
    path.lineTo(midX - halfSize, midY + halfSize - 40);
    canvas.drawPath(path, paint);
  }

  @override
  ShapeBorder scale(double t) => this;
}
