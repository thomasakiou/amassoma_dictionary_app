# Amassoma Dictionary

Flutter mobile dictionary for Amassoma/Izon vocabulary. The app uses the public approved-vocabulary endpoint from the existing Amassoma Hub API. Saved words, recent entries, and the last fetched vocabulary are stored on-device.

## Requirements

- Flutter 3.24 or newer
- Android SDK for Android builds
- Xcode on macOS for iOS builds

## Run

```powershell
flutter pub get
flutter run
```

The default API base is `https://vmi2848672.contaboserver.net/amassoma`. To use another deployment:

```powershell
flutter run --dart-define=API_BASE_URL=https://example.com/amassoma
```

The app combines approved rows from `GET /dictionary` and `GET /api/learning/vocabulary`. Dictionary phonetic markup is reduced to readable text, and entry audio plays when an `audio_url` is available. The orthographic index bundles the existing 28 alphabet recordings from the Amassoma Hub frontend, so letter sounds work offline.

The backend provides word/translation and phonetic fields, not the richer sense, example, and dialect schemas in the neighboring design references. The app only displays fields the endpoints provide; pronunciation capture and authenticated contributions are not part of this first version.

## Build

```powershell
flutter build apk
flutter build appbundle
```

The page design references remain in the parent `amassoma_dictionary_app` directory; this folder is the standalone Git repository for the Flutter app.
