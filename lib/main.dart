import 'dart:io';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/trip_provider.dart';
import 'core/providers/connectivity_Notifier.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/staff_profile_screen.dart';
import 'core/services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    await Firebase.initializeApp();
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    // Global Error for UI crashes
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFC62828), size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'The application encountered an unexpected error. Our team has been notified.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => navigatorKey.currentState?.popUntil((route) => route.isFirst),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
                  child: const Text('Back to Safety', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    };

    FlutterError.onError = (details) {
      if (details.exception is SocketException || details.exception is TimeoutException) {
        FirebaseCrashlytics.instance.recordError(details.exception, details.stack, fatal: false);
      } else {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      bool isNetworkError = error is SocketException || error is TimeoutException || error.toString().contains('SocketException');
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: !isNetworkError);
      return true;
    };
  } catch (e) {
    debugPrint('Firebase init error $e');
  }

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => ScreenUtilInit(
        designSize: const Size(360, 640),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => TripProvider()),
            ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
          ],
          child: const TicketValidatorApp(),
        ),
      ),
    ),
  );

  Future.delayed(const Duration(seconds: 1), () {
    NotificationService.initialize();
  });
}

class TicketValidatorApp extends StatelessWidget {
  const TicketValidatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      locale: DevicePreview.locale(context),
      title: 'Freeway Ticket Validator 2.0',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
      builder: (context, child) {
        child = DevicePreview.appBuilder(context, child);

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: Stack(
            children: [
              child,
              Consumer<ConnectivityProvider>(
                builder: (context, connectivity, _) {
                  if (connectivity.isOnline && !connectivity.showRestored) return const SizedBox.shrink();

                  final bool isOnline = connectivity.isOnline;
                  final Color baseColor = isOnline ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
                  final Color bgColor = isOnline ? const Color(0xFFE8F5E9) : const Color(0xFFFFF2F2);

                  return Positioned(
                    bottom: MediaQuery.of(context).padding.bottom + 20,
                    left: 20,
                    right: 20,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: baseColor.withValues(alpha: 0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                              color: baseColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isOnline ? 'Back Online' : 'No Internet Connection',
                                style: TextStyle(
                                  color: baseColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (!isOnline)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(baseColor.withValues(alpha: 0.5)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await context.read<TripProvider>().tryAutoLogin();
    if (mounted) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final user = context.watch<TripProvider>().currentUser;
    return user != null ? const StaffProfileScreen() : const LoginScreen();
  }
}


