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
