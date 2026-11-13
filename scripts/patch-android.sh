#!/usr/bin/env bash
set -euo pipefail
sed -i "s/minSdkVersion = [0-9]*/minSdkVersion = 24/" android/variables.gradle
# custom launcher icon (instead of the default Capacitor icon)
if [ -d resources/android-res ]; then
  cp -r resources/android-res/. android/app/src/main/res/
  sed -i "s/#FFFFFF/#0C1931/" android/app/src/main/res/values/ic_launcher_background.xml
fi
APP_ID=$(node -p "require('./www/admob.config.json').appId")
MANIFEST=android/app/src/main/AndroidManifest.xml
if ! grep -q "gms.ads.APPLICATION_ID" "$MANIFEST"; then
  sed -i "s#</application>#    <meta-data android:name=\"com.google.android.gms.ads.APPLICATION_ID\" android:value=\"$APP_ID\"/>\n    </application>#" "$MANIFEST"
fi
# version (Play requires versionCode to increase each upload)
VC=${VERSION_CODE:-1}
sed -i "s/versionCode [0-9]*/versionCode $VC/" android/app/build.gradle
sed -i "s/versionName \"[^\"]*\"/versionName \"1.0.$VC\"/" android/app/build.gradle
# release signing from env (only if keystore provided)
if [ -n "${KEYSTORE_PATH:-}" ]; then
cat >> android/app/build.gradle <<GRADLE

android {
    signingConfigs {
        release {
            storeFile file("$KEYSTORE_PATH")
            storePassword System.getenv("KEYSTORE_PASSWORD")
            keyAlias System.getenv("KEY_ALIAS")
            keyPassword System.getenv("KEY_PASSWORD")
        }
    }
    buildTypes { release { signingConfig signingConfigs.release } }
}
GRADLE
fi
echo "Patched Android project (AdMob app id: $APP_ID, versionCode: $VC)"
