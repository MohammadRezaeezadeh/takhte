# Releasing

## Signing
CI looks for these repository secrets (Settings → Secrets and variables → Actions):

| Secret | Meaning |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 release.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | keystore password |
| `ANDROID_KEY_ALIAS` | key alias |
| `ANDROID_KEY_PASSWORD` | key password |

Create a keystore once with:

```bash
keytool -genkeypair -v -keystore release.jks -alias haftnard -keyalg RSA -keysize 2048 -validity 10000
```

If the secrets are absent CI uses a keystore it generated itself and caches
(`haftnard-ci-keystore-v1`). If that cache is evicted a new key is generated, so
an installed CI build may need to be uninstalled before installing a newer one.
Locally, without `android/key.properties`, release builds are debug-signed.

## Tagging
Push a tag `vX.Y.Z` — CI attaches the APK and AAB to a GitHub Release.
