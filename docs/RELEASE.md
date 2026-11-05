# Releasing

**Every push to `main` or `claude/vibrant-newton-gzwmx2` that passes CI publishes
a GitHub Release automatically** — no tags need to be pushed by hand.

* Tag = `v<version>` from `pubspec.yaml` (e.g. `v1.0.0`). If that tag exists,
  CI uses `v<version>-build.<run>`. A commit that is already released is skipped.
* Assets: `haftnard-arm64.apk` (most phones), `haftnard-armv7.apk` (old phones),
  `haftnard-universal.apk`, `haftnard.aab` (Play Store). Newest = "Latest".
* Notes: commit subjects since the previous release.
* To ship a new version: bump `version:` in `pubspec.yaml` and push.

## Signing
* Default: the committed CI key `android/ci/haftnard-ci.jks` (alias `haftnard`,
  password `haftnard-ci`). Stable, so updates install over older builds.
  It is public — fine for testing, **not** for a Play Store listing.
* Real key: add these repository secrets and CI uses them automatically:
  `ANDROID_KEYSTORE_BASE64` (`base64 -w0 release.jks`), `ANDROID_KEYSTORE_PASSWORD`,
  `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.
  Create a key once with:

```bash
keytool -genkeypair -v -keystore release.jks -alias haftnard -keyalg RSA -keysize 2048 -validity 10000
```

Switching from the CI key to a real key requires uninstalling the old build once.

## Publishing checklist (راهنمای انتشار)
1. **Signing key (required once before Google Play):** create `release.jks` with the `keytool` command above. Add the four repository secrets (Settings → Secrets and variables → Actions) and push any commit; CI then signs with your key. Keep the `.jks` file and passwords safe: Play needs the same key for every update. With Play App Signing you upload with this key and Google re-signs.
2. **Build:** every green push publishes a GitHub Release with `haftnard.aab` (upload this to Play) and APKs (direct install, e.g. Bazaar / Myket / direct download).
3. **Store page:** `docs/store/` has everything:
   - `listing_fa.md` and `listing_en.md`: name, short and full description, category, rating.
   - `icon-512.png` and `feature-graphic.png` (1024×500).
   - `screenshots/`: eight Persian phone shots, 1080×1920 (9:16); `previews/` (1080×1920) and `previews_landscape/` (1920×1080, 16:9) are the captioned store versions.
   - `privacy.md`: a privacy policy to host and link (no data collected).
   - Re-render the graphics with `flutter test tool/store_assets_test.dart`.
4. **Content rating questionnaire:** no violence, no real-money gambling (cards are a game mechanic, no purchases with money), no user data.
5. **Release notes** for a version go in `docs/release_notes/v<version>.md`; CI uses them instead of the commit list.

**فارسی، خلاصه:**
1. یک بار کلید امضا بسازید و چهار secret را در GitHub اضافه کنید. فایل کلید و رمزها را جای امن نگه دارید.
2. بعد از هر push سبز، فایل `haftnard.aab` را از صفحه‌ی Release در Google Play بارگذاری کنید. برای کافه‌بازار، مایکت یا نصب مستقیم، فایل APK را بردارید.
3. متن‌ها، آیکون، تصویر شاخص، اسکرین‌شات‌ها و سیاست حریم خصوصی در پوشه‌ی `docs/store/` آماده است.
