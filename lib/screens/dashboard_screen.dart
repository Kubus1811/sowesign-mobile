import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/course.dart';
import '../models/student_profile.dart';
import '../services/sowesign_api_service.dart';
import '../services/storage_service.dart';
import '../widgets/course_card.dart';
import 'settings_screen.dart';
import 'signature_modal.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  StudentProfile _profile = const StudentProfile(
    institutionCode: '6109',
    email: '',
    refreshToken: '',
    isDryRun: true,
  );

  bool _isLoading = true;
  String? _errorMessage;
  List<Course> _courses = [];
  Timer? _statusRefreshTimer;

  @override
  void initState() {
    super.initState();
    _initApp();
    // Rafraîchissement périodique léger des statuts dynamiques toutes les 30 secondes
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _statusRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initApp() async {
    setState(() => _isLoading = true);
    final saved = await StorageService.loadProfile();
    setState(() => _profile = saved);

    if (_profile.isConfigured) {
      await _loadCourses();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Rafraîchissement de la session si besoin
      var currentProfile = _profile;
      if (currentProfile.accessToken == null) {
        currentProfile = await SoWeSignApiService.refreshSession(currentProfile);
        await StorageService.saveProfile(currentProfile);
        setState(() => _profile = currentProfile);
      }

      // 2. Récupération des cours du jour
      final fetchedCourses =
          await SoWeSignApiService.fetchDailyCourses(currentProfile);

      setState(() {
        _courses = fetchedCourses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => SettingsScreen(
          initialProfile: _profile,
          onProfileSaved: (updated) {
            setState(() => _profile = updated);
            _loadCourses();
          },
        ),
      ),
    );
  }

  void _openSigningModal(Course course) {
    SignatureModal.show(
      context: context,
      course: course,
      profile: _profile,
      onSignedSuccess: () {
        // Rafraîchir les cours après signature
        _loadCourses();
      },
    );
  }

  String _getFormattedToday() {
    try {
      return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now());
    } catch (_) {
      final now = DateTime.now();
      const days = [
        'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
      ];
      const months = [
        'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
        'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
      ];
      return '${days[now.weekday - 1]} ${now.day} ${months[now.month - 1]} ${now.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayFormatted = _getFormattedToday();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              todayFormatted.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _profile.isConfigured
                  ? 'Bonjour, ${_profile.displayName}'
                  : 'SoWeSign Étudiant',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          // Badge Mode Simulation / Live
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _profile.isDryRun ? Colors.amber.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _profile.isDryRun
                    ? Colors.amber.shade300
                    : Colors.green.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _profile.isDryRun ? Icons.shield_rounded : Icons.flash_on_rounded,
                  size: 13,
                  color: _profile.isDryRun
                      ? Colors.amber.shade800
                      : Colors.green.shade800,
                ),
                const SizedBox(width: 4),
                Text(
                  _profile.isDryRun ? 'Dry-Run' : 'Live',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _profile.isDryRun
                        ? Colors.amber.shade800
                        : Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            tooltip: 'Réglages',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCourses,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Synchronisation des cours...',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (!_profile.isConfigured) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_circle_outlined,
                  size: 64, color: Colors.blue.shade300),
              const SizedBox(height: 16),
              const Text(
                'Compte non configuré',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Veuillez renseigner votre code école, votre e-mail et votre refreshToken dans les réglages pour accéder à vos cours.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _openSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Accéder aux Réglages'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 54, color: Colors.red.shade400),
              const SizedBox(height: 14),
              const Text(
                'Impossible de charger les cours',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _loadCourses,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_courses.isEmpty) {
      return Center(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Column(
                children: [
                  Icon(Icons.event_available_rounded,
                      size: 64, color: Colors.green.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucun cours aujourd\'hui',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vous n\'avez aucun cours programmé sur SoWeSign pour cette date.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: _loadCourses,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Actualiser'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _courses.length,
      itemBuilder: (ctx, index) {
        final course = _courses[index];
        return CourseCard(
          course: course,
          onSignPressed: () => _openSigningModal(course),
        );
      },
    );
  }
}
