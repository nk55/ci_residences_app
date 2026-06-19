import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/favorites_screen.dart';
import 'screens/main_navigation_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CiResidencesApp());
}

class CiResidencesApp extends StatefulWidget {
  const CiResidencesApp({super.key});

  @override
  State<CiResidencesApp> createState() => _CiResidencesAppState();
}

class _CiResidencesAppState extends State<CiResidencesApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  bool _hasHandledPaymentLink = false;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingUri(initialUri);
      }
    } catch (error) {
      debugPrint('Erreur initial deep link: $error');
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleIncomingUri(uri);
      },
      onError: (Object error) {
        debugPrint('Erreur deep link: $error');
      },
    );
  }

  void _handleIncomingUri(Uri uri) {
    debugPrint('Deep link reçu: $uri');

    if (uri.scheme != 'ciresidences') return;
    if (uri.host != 'payment-return') return;

    final status = (uri.queryParameters['status'] ?? '').toLowerCase();

    if (status == 'success') {
      if (_hasHandledPaymentLink) return;
      _hasHandledPaymentLink = true;

      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );

      messengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Paiement réussi 🎉'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        _hasHandledPaymentLink = false;
      });

      return;
    }

    if (status == 'failed' || status == 'cancelled') {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );

      messengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Paiement échoué ❌'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        _hasHandledPaymentLink = false;
      });

      return;
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.poppinsTextTheme();

    return MaterialApp(
      title: 'CI Résidences',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: textTheme,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF243B8F),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      ),
      home: const SplashScreen(),
      routes: {
        '/favorites': (context) => const FavoritesScreen(),
        '/home': (context) => const MainNavigationScreen(),
      },
    );
  }
}

// =========================
// SPLASH SCREEN
// =========================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icon.png',
              width: 120,
            ),
            const SizedBox(height: 20),
            const Text(
              'CI Résidences',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}