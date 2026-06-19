import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ads_screen.dart';
import 'artisans_screen.dart';
import 'dashboard_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'residences_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _isLoggedIn = false;
  bool _isLoadingSession = true;
  String _username = '';

  final List<Widget> _screens = const [
    HomeScreen(),
    ResidencesScreen(),
    ArtisansScreen(),
    AdsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserSession();
    });
  }

  Future<void> _loadUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      setState(() {
        _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
        _username = prefs.getString('username') ?? '';
        _isLoadingSession = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoggedIn = false;
        _username = '';
        _isLoadingSession = false;
      });
    }
  }

  Future<void> _openLogin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );

    await _loadUserSession();
  }

  Future<void> _openDashboard() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DashboardScreen(),
      ),
    );

    await _loadUserSession();
  }

  Future<void> _openFavorites() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FavoritesScreen(),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('is_logged_in');
      await prefs.remove('username');
      await prefs.remove('token');

      if (!mounted) return;

      setState(() {
        _isLoggedIn = false;
        _username = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Déconnexion réussie'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la déconnexion'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'CI Résidences';
      case 1:
        return 'Résidences';
      case 2:
        return 'Artisans';
      case 3:
        return 'Publier';
      default:
        return 'CI Résidences';
    }
  }

  String _getSubtitle() {
    switch (_currentIndex) {
      case 0:
        return 'Trouvez votre prochain espace';
      case 1:
        return 'Découvrez les meilleures résidences';
      case 2:
        return 'Des artisans prêts à intervenir';
      case 3:
        return 'Devenez artisan ou propriétaire';
      default:
        return '';
    }
  }

  Widget _buildAppBarTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getTitle(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        Text(
          _getSubtitle(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  PopupMenuButton<String> _buildUserMenu() {
    return PopupMenuButton<String>(
      tooltip: 'Compte',
      onSelected: (value) async {
        if (value == 'login') {
          await _openLogin();
        } else if (value == 'dashboard') {
          await _openDashboard();
        } else if (value == 'logout') {
          await _logout();
        }
      },
      itemBuilder: (context) {
        if (_isLoggedIn) {
          return [
            PopupMenuItem<String>(
              enabled: false,
              value: 'user',
              child: Text(
                _username.isNotEmpty ? _username : 'Connecté',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'dashboard',
              child: Row(
                children: [
                  Icon(Icons.dashboard_outlined),
                  SizedBox(width: 10),
                  Text('Tableau de bord'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded),
                  SizedBox(width: 10),
                  Text('Déconnexion'),
                ],
              ),
            ),
          ];
        }

        return const [
          PopupMenuItem<String>(
            value: 'login',
            child: Row(
              children: [
                Icon(Icons.login_rounded),
                SizedBox(width: 10),
                Text('Connexion'),
              ],
            ),
          ),
        ];
      },
      icon: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFE8EDFF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          _isLoggedIn ? Icons.person_rounded : Icons.person_outline_rounded,
          color: const Color(0xFF243B8F),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingSession) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF243B8F),
        ),
      );
    }

    return _screens[_currentIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: false,
        backgroundColor: const Color(0xFFF5F7FB),
        titleSpacing: 16,
        title: _buildAppBarTitle(),
        actions: [
          IconButton(
            tooltip: 'Favoris',
            onPressed: _openFavorites,
            icon: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 10,
                    offset: Offset(0, 4),
                    color: Color(0x11000000),
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                color: Color(0xFF243B8F),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 4),
          _buildUserMenu(),
          const SizedBox(width: 10),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            indicatorColor: const Color(0xFFE8EDFF),
            height: 74,
            selectedIndex: _currentIndex,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Accueil',
              ),
              NavigationDestination(
                icon: Icon(Icons.apartment_outlined),
                selectedIcon: Icon(Icons.apartment_rounded),
                label: 'Résidences',
              ),
              NavigationDestination(
                icon: Icon(Icons.build_outlined),
                selectedIcon: Icon(Icons.build_rounded),
                label: 'Artisans',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_business_outlined),
                selectedIcon: Icon(Icons.add_business_rounded),
                label: 'Publier',
              ),
            ],
          ),
        ),
      ),
    );
  }
}