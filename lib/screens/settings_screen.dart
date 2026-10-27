import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../services/sowesign_api_service.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  final StudentProfile initialProfile;
  final Function(StudentProfile updated) onProfileSaved;

  const SettingsScreen({
    super.key,
    required this.initialProfile,
    required this.onProfileSaved,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _institutionController;
  late TextEditingController _emailController;
  late TextEditingController _refreshTokenController;
  late bool _isDryRun;

  bool _isTesting = false;
  String? _testStatusMessage;
  bool? _isTestSuccess;

  @override
  void initState() {
    super.initState();
    _institutionController =
        TextEditingController(text: widget.initialProfile.institutionCode);
    _emailController = TextEditingController(text: widget.initialProfile.email);
    _refreshTokenController =
        TextEditingController(text: widget.initialProfile.refreshToken);
    _isDryRun = widget.initialProfile.isDryRun;
  }

  @override
  void dispose() {
    _institutionController.dispose();
    _emailController.dispose();
    _refreshTokenController.dispose();
    super.dispose();
  }

  Future<void> _testAndSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTesting = true;
      _testStatusMessage = null;
      _isTestSuccess = null;
    });

    final draftProfile = widget.initialProfile.copyWith(
      institutionCode: _institutionController.text.trim(),
      email: _emailController.text.trim(),
      refreshToken: _refreshTokenController.text.trim(),
      isDryRun: _isDryRun,
    );

    try {
      // Test de rafraîchissement auprès de l'API SoWeSign
      final connectedProfile =
          await SoWeSignApiService.refreshSession(draftProfile);

      // Persistance sécurisée locale
      await StorageService.saveProfile(connectedProfile);
      widget.onProfileSaved(connectedProfile);

      setState(() {
        _isTesting = false;
        _isTestSuccess = true;
        _testStatusMessage =
            'Connexion réussie ! Identifié en tant que ${connectedProfile.displayName} (ID: ${connectedProfile.studentId ?? 'Non renseigné'}).';
      });
    } catch (e) {
      setState(() {
        _isTesting = false;
        _isTestSuccess = false;
        _testStatusMessage = 'Échec de connexion : ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Réglages & Identifiants',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bannière explicative
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: Colors.blue.shade700, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Renseignez ici vos identifiants SoWeSign pour synchroniser vos cours et émarger de façon autonome.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Code Établissement
              const Text(
                'Code Établissement',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _institutionController,
                decoration: InputDecoration(
                  hintText: 'ex: 6109 (EFREI Paris)',
                  prefixIcon: const Icon(Icons.school_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Veuillez saisir le code de l\'école'
                    : null,
              ),
              const SizedBox(height: 16),

              // Adresse Email
              const Text(
                'Adresse Email Étudiante',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'prenom.nom@ecole.fr',
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (val) => (val == null || !val.contains('@'))
                    ? 'Veuillez saisir une adresse email valide'
                    : null,
              ),
              const SizedBox(height: 16),

              // Refresh Token SoWeSign
              const Text(
                'Jeton d\'authentification (RefreshToken)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _refreshTokenController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Collez ici votre jeton JWT de session SoWeSign...',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.key_rounded),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Le refreshToken est requis'
                    : null,
              ),
              const SizedBox(height: 24),

              // Interrupteur Mode Dry-Run / Sécurité
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _isDryRun ? Colors.amber.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isDryRun
                        ? Colors.amber.shade300
                        : Colors.red.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isDryRun ? Icons.shield_rounded : Icons.warning_amber_rounded,
                      color: _isDryRun ? Colors.amber.shade800 : Colors.red.shade800,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mode Simulation (Dry-Run)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _isDryRun
                                  ? Colors.amber.shade900
                                  : Colors.red.shade900,
                            ),
                          ),
                          Text(
                            _isDryRun
                                ? 'Actif : aucune signature réelle n\'est envoyée aux serveurs.'
                                : 'ATTENTION : Les émargements validés seront réels.',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isDryRun
                                  ? Colors.amber.shade800
                                  : Colors.red.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isDryRun,
                      activeColor: Colors.amber.shade700,
                      onChanged: (val) {
                        setState(() => _isDryRun = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Message de retour de test
              if (_testStatusMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isTestSuccess == true
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isTestSuccess == true
                          ? Colors.green.shade300
                          : Colors.red.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isTestSuccess == true
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        color: _isTestSuccess == true
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _testStatusMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            color: _isTestSuccess == true
                                ? Colors.green.shade900
                                : Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Bouton Tester & Sauvegarder
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isTesting ? null : _testAndSave,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _isTesting
                        ? 'Test de connexion en cours...'
                        : 'Tester la connexion & Enregistrer',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
