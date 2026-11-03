# SoWeSign Étudiant — Application Mobile Native (iOS & Android)

Application mobile multiplateforme (**iOS & Android**) développée en Flutter / Dart 100% autonome. Elle permet aux étudiants de consulter en temps réel leur planning de cours du jour, de suivre les fenêtres d'émargement et d'émarger de manière fiable et sécurisée sans aucun serveur intermédiaire.

---

## 📲 Téléchargement Direct & Installation sans PC

Les applications sont compilées automatiquement par les serveurs GitHub Actions et mises à disposition dans la section **Releases** :
👉 **[Accéder aux Téléchargements des Applications (GitHub Releases)](https://github.com/Kubus1811/sowesign-mobile/releases/tag/latest)**

| Plateforme | Fichier direct | Méthode d'installation sans PC |
| :--- | :--- | :--- |
| 🍎 **iPhone (iOS)** | [`SoWeSign-iOS.ipa`](https://github.com/Kubus1811/sowesign-mobile/releases/download/latest/SoWeSign-iOS.ipa) | **Direct via Scarlet** (Safari) en 2 minutes (aucun ordi, aucun câble) |
| 🤖 **Android** | [`SoWeSign-Android.apk`](https://github.com/Kubus1811/sowesign-mobile/releases/download/latest/SoWeSign-Android.apk) | Téléchargement direct & ouverture du fichier `.apk` |

---

## 🍎 Guide d'Installation sur iPhone via Scarlet (Zéro PC, Zéro Câble)

### Étape 1 : Installer Scarlet sur votre iPhone
1. Ouvrez **Safari** sur votre iPhone et rendez-vous sur le site officiel : **[usescarlet.com](https://usescarlet.com)**.
2. Descendez en bas de la page et touchez le bouton rouge **Install**.
3. Choisissez **Direct Install** (attendez les 10 secondes du compte à rebours).
4. Une invite iOS apparaît : appuyez sur **Ouvrir**, puis sur **Installer**.
5. L'icône Scarlet apparaît sur l'écran d'accueil de votre iPhone.

### Étape 2 : Valider le certificat dans les réglages iOS
1. Sur votre iPhone, ouvrez **Réglages** > **Général** > **VPN et gestion des appareils**.
2. Dans la section *App d'entreprise*, touchez le profil de certificat qui vient d'apparaître.
3. Touchez **Faire confiance à ...** et confirmez.

### Étape 3 : Installer l'application SoWeSign
1. Téléchargez le fichier **[SoWeSign-iOS.ipa](https://github.com/Kubus1811/sowesign-mobile/releases/download/latest/SoWeSign-iOS.ipa)** depuis Safari sur votre iPhone.
2. Ouvrez l'application **Scarlet**.
3. Touchez l'icône d'importation (la flèche vers le bas ou le carré en haut à droite).
4. Sélectionnez le fichier `SoWeSign-iOS.ipa` dans vos Téléchargements.
5. Touchez **Installer** : l'application SoWeSign s'installe comme une véritable application native sur votre écran d'accueil !

---

## 🤖 Guide d'Installation sur Android

1. Téléchargez directement **[SoWeSign-Android.apk](https://github.com/Kubus1811/sowesign-mobile/releases/download/latest/SoWeSign-Android.apk)** sur votre smartphone.
2. Touchez le fichier dans vos Téléchargements.
3. Appuyez sur **Installer** (autorisez l'installation d'applications inconnues si demandé).
4. L'application est prête à l'emploi.

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
│   ├── main.dart                      # Point d'entrée, thème & gestionnaire d'erreur
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
