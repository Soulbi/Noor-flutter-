# Noor v2 (Flutter)

Réécriture native de l'app Noor, en Flutter (Android + iOS), pour remplacer
la version actuelle basée sur Capacitor/WebView.

## État actuel — Étape 1/8

Squelette du projet : thème visuel (identique à la version web : mêmes
couleurs, mêmes polices, clair/sombre, 3 accents), navigation à 5 onglets,
réglages de base (thème, accent, langue). Les modules Prières, Jeûne, Coran,
notifications natives + adhan, et le widget écran d'accueil arrivent dans
les étapes suivantes.

## Pourquoi `android/` et `ios/` ne sont pas dans ce dépôt

Seul le code de l'application (`pubspec.yaml`, `lib/`, `assets/`) est
commité. Les dossiers natifs `android/` et `ios/` sont régénérés à chaque
build par `.github/workflows/build.yml` (commande `flutter create`), puis
automatiquement corrigés pour utiliser le bon identifiant d'app
(`fr.noor.app` — **ne doit jamais changer**, c'est celui déjà publié sur le
Play Store) et la bonne configuration de signature.

## Mise en place nécessaire sur GitHub (une fois)

1. **Créer ce nouveau dépôt** (ex. `noor-flutter`) et y pousser ces fichiers.
2. **Réutiliser le même fichier de clé de signature Android** que pour
   l'ancien dépôt `noor-android` (le `.keystore`/`.jks` original de
   PWABuilder) — c'est obligatoire pour que le Play Store considère ce
   nouveau build comme une mise à jour de l'app existante, et non une
   app différente. Les mêmes 4 secrets doivent être recréés dans **ce**
   dépôt (`Settings → Secrets and variables → Actions`) :
   `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
   `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` — les secrets ne se copient
   pas d'un dépôt à l'autre, il faut le fichier de clé original pour les
   recréer ici (voir `android/SIGNING.md` dans l'ancien dépôt pour la
   procédure).
3. **iOS** : la première build du workflow compile une version iOS **non
   signée** (juste pour vérifier que ça compile). Pour publier sur l'App
   Store, il faudra un compte développeur Apple (99$/an) — on configurera
   la signature une fois que tu l'auras.
