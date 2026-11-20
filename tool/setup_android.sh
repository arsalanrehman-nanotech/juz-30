#!/usr/bin/env bash
# Creates the Android platform folder (if it is missing), sets the app name and
# installs the launcher icons. Run once from anywhere:  bash tool/setup_android.sh
# Requires the Flutter SDK on PATH. Pillow (pip install pillow) is optional and
# only needed for the custom launcher icon.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -d android ]; then
  echo "android/ already exists - keeping it."
else
  tmp="$(mktemp -d)"
  flutter create --platforms=android --project-name juz30_hifz --org com.hifz "$tmp/scaffold"
  cp -R "$tmp/scaffold/android" ./android
  rm -rf "$tmp"
fi

manifest="android/app/src/main/AndroidManifest.xml"
sed -i.bak 's/android:label="[^"]*"/android:label="Juz 30 Hifz"/' "$manifest" && rm -f "$manifest.bak"

if python3 -c "import PIL" >/dev/null 2>&1; then
  python3 tool/make_icons.py android/app/src/main/res
else
  echo "Pillow not installed - keeping the default launcher icon (pip install pillow to change)."
fi
echo "Android platform ready."
