# Juz 30 Hifz Revision (Flutter, Android, offline)

A random-ayah revision app for Juz 30 (Amma Para). A random ayah is shown; you recite from the
next ayah to the end of the surah, and tap **Show Full Ayah** if you get stuck.

## Build the APK

The Flutter and Android toolchains were not available where this project was written, so
**the app has not been compiled or run yet**. Pick one of these routes.

### A. Cloud build (no installs needed)
1. Create a GitHub repository and upload the contents of this folder.
2. Open the **Actions** tab, choose **Build Android APK**, click **Run workflow**.
3. When it finishes, download `juz30-hifz-apk` from the run's Artifacts, unzip it, copy
   `app-release.apk` to your phone and install it (allow "install unknown apps").

### B. On your own computer
Install Flutter (stable) and the Android SDK, then in this folder:

```bash
bash tool/setup_android.sh      # creates android/, app name and launcher icon
flutter pub get
flutter test                    # optional
flutter build apk --release
```
The APK is at `build/app/outputs/flutter-apk/app-release.apk`.
On Windows without bash: run `flutter create --platforms=android --project-name juz30_hifz --org com.hifz scaffold`
in a temporary place, copy its `android` folder into this project, then continue from `flutter pub get`.

The release APK is signed with the debug key, which is fine for installing on your own phone.

## Quran data
`assets/quran/juz30.json` is extracted verbatim by `tool/build_quran_data.py` from the QUL
Uthmani text (Madinah Mushaf). No text was typed or generated. Boundaries (78:1 to 114:6,
564 ayahs, 37 surahs) and per-surah counts were checked against two other datasets.
See `docs/DATA_VERIFICATION.md`, including the short list of ayahs whose secondary marks are
encoded differently between sources and are worth a glance against a printed Mushaf.

## Behaviour notes
- **Show Full Ayah** reveals the *next* ayah (the one you are recalling) by default. Settings
  can switch it to re-show the selected ayah.
- Easy = surahs of 11 ayahs or fewer. Normal avoids recently asked ayahs. Challenge never
  repeats an ayah until all in your selection have been asked.
- Progress is stored on the device (SharedPreferences). No internet permission is used.

## Font licence
`assets/fonts/KFGQPC_Uthmanic_Script_Hafs.otf` is the KFGQPC Uthmanic Script (Hafs) font, shipped
unmodified. Its licence (embedded in the font file) allows free use, copying and distribution of
the unmodified font, and forbids selling it. See `docs/FONT_LICENSE.txt`.

## Layout
`lib/data` models and loader, `lib/logic` picker, session, pool, settings and stats (pure Dart),
`lib/state` app state, `lib/services` storage, `lib/screens` and `lib/widgets` UI, `test/` unit tests.
