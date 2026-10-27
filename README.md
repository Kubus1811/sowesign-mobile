# SoWeSign Étudiant — Application Mobile (Flutter)

Application mobile multiplateforme (**iOS & Android**) développée en Flutter / Dart 100% autonome. Elle permet aux étudiants de consulter en temps réel leur planning de cours du jour, de suivre les fenêtres d'émargement et d'émarger de manière fiable et sécurisée.

---

## 📱 Fonctionnalités Principales

1. **Configuration Sécurisée du Profil Étudiant** :
   - Saisie du code établissement (ex: `6109` - EFREI Paris), de l'e-mail étudiant et du `refreshToken`.
   - Bouton de vérification de session avec test direct auprès de l'API SoWeSign.
   - Persistance sécurisée chiffrée sur le terminal.

2. **Tableau de Bord des Cours du Jour** :
   - Synchronisation automatique dès l'ouverture et geste *Pull-to-Refresh*.
   - Cartes de cours détaillées : titre de la matière, enseignant, salle, créneau horaire.
   - Badges d'état dynamiques en temps réel :
     - 🟢 **Émargement ouvert** (période d'émargement en cours)
     - 🔵 **Déjà émargé** (présence validée)
     - ⏳ **À venir** (avec compte à rebours avant ouverture)
     - ⚪ **Clos** (cours terminé)

3. **Garde-fou Strict — Mode Simulation (Dry-Run)** :
   - Activé par défaut dans les réglages et visible en permanence via un badge dans l'en-tête.
   - En mode Dry-Run, l'application exécute la préparation cryptographique et les requêtes préliminaires, mais **n'envoie jamais l'émargement réel** vers le serveur SoWeSign.

4. **Double Mode de Signature Conforme** :
   - **Pad tactile interactif** : Dessinez votre signature manuellement au doigt avec votre écran tactile.
   - **Générateur procédural réaliste** : Génération instantanée d'un tracé manuscrit unique (splines lissées, hash MD5 unique à chaque émargement).
   - **Encodage WebKit natif** : Export PNG 640x480 pixels en palette 1-bit (`color_type=3`, `bit_depth=1`), transparence `tRNS` et résolution `pHYs` 96 DPI identique au canvas WebKit iOS.

---

## 🛠️ Architecture Technique (Pure Dart)

L'application ne dépend d'aucun serveur intermédiaire ni de script externe : tout est exécuté localement sur le smartphone de l'utilisateur.

```
sowesign_mobile_app/
├── lib/
│   ├── main.dart                      # Point d'entrée & Thème Material 3
│   ├── models/
│   │   ├── course.dart                # Modèle cours, fenêtres et statuts
│   │   └── student_profile.dart       # Profil étudiant & persistance
│   ├── services/
│   │   ├── crypto_service.dart        # Moteur AES-256-CBC EVP_BytesToKey MD5
│   │   ├── png_encoder_service.dart   # Encodeur PNG 1-bit WebKit & Tracés
│   │   ├── sowesign_api_service.dart  # Client REST SoWeSign & Dry-Run
│   │   └── storage_service.dart       # Stockage persistant sécurisé
│   ├── screens/
│   │   ├── dashboard_screen.dart      # Planning du jour & statut en temps réel
│   │   ├── settings_screen.dart       # Écran de configuration des identifiants
│   │   └── signature_modal.dart       # Modal d'émargement (Pad tactile & Auto)
│   └── widgets/
│       ├── course_card.dart           # Carte de cours avec bouton émarger
│       ├── status_badge.dart          # Badge d'état dynamique coloré
│       └── signature_pad.dart         # CustomPainter pour dessin tactile
├── test/
│   └── crypto_service_test.dart       # Tests unitaires du chiffrement
└── pubspec.yaml                       # Dépendances Flutter
```

---

## 🚀 Guide d'Installation et Exécution

### Prérequis
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version `>= 3.0.0`)
- **Pour iOS** : macOS avec Xcode installé et CocoaPods (`pod install`).
- **Pour Android** : Android Studio avec SDK Android (API level >= 21).

### 1. Installation des dépendances
Dans le dossier du projet :
```bash
cd sowesign_mobile_app
flutter pub get
```

### 2. Lancer les tests unitaires
Pour vérifier la conformité des fonctions cryptographiques et du modèle de données :
```bash
flutter test
```

### 3. Exécuter sur iPhone (iOS)
```bash
# Sur simulateur iOS ou iPhone connecté par USB
flutter run -d ios
```

### 4. Exécuter sur Android
```bash
# Sur émulateur ou smartphone Android en mode débogage USB
flutter run -d android
```

### 5. Compiler l'APK Android autonome
```bash
flutter build apk --release
# Le fichier APK généré se trouvera dans :
# build/app/outputs/flutter-apk/app-release.apk
```
