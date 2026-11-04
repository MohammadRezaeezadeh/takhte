# Decisions

One line per decision: **decision** — reason.

- **Flutter 3.47.9 stable pinned in CI** — reproducible builds; bump deliberately.
- **Riverpod (flutter_riverpod 3.x) for state management** — compile-safe providers, easy to test, no BuildContext coupling.
- **very_good_analysis lints, minus `public_member_api_docs` and the 80-col rule** — strict but practical for game code.
- **Application id `com.haftnard.game`, minSdk 23** — matches spec; neutral id.
- **CI signing: secrets → cached CI keystore → freshly generated keystore** — never fails without secrets; cached key keeps upgrades installable most of the time.
- **Release builds use R8 minify + resource shrinking** — smaller APK.
