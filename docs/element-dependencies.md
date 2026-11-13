# Element-controlled build dependencies

> **Provenance:** static reading only of `gradle/libs.versions.toml`, `settings.gradle.kts`,
> `plugins/build.gradle.kts`, all `build.gradle.kts` usages, `.gitmodules`, `tools/` and `.github/workflows/`
> at `origin/develop`. Nothing was resolved, downloaded or built; publishing repositories and
> upstream build reproducibility are **unverified** and marked as such.

## Repository declarations

`settings.gradle.kts` (`FAIL_ON_PROJECT_REPOS`) resolves from: Gradle Plugin Portal, Google (exclusive for
`android*`/`androidx*`/firebase groups), Maven Central, JitPack (restricted to
`com.github.matrix-org:matrix-analytics-events` and `com.github.philburk:jsyn`), and a `flatDir`
`libraries/matrix/libs` (directory does not exist in the tree). **No Element-operated Maven repository is
declared.** The `io.element.android:*` and `org.matrix.rustcomponents:*` coordinates have no repository filter, so
they resolve from Maven Central (assumed, unverified; no pin by checksum or dependency verification file
was seen).

## Inventory

| # | Artifact / source | Version | Resolved from | What it is | Upstream public source | Recommendation |
|---|---|---|---|---|---|---|
| 1 | `org.matrix.rustcomponents:sdk-android` | 26.09.9 | Maven Central (assumed) | Kotlin/UniFFI bindings plus prebuilt native libs of matrix-rust-sdk; the whole Matrix client core (`libraries/matrix/impl`) | https://github.com/matrix-org/matrix-rust-sdk, packaging at https://github.com/matrix-org/matrix-rust-components-kotlin | **Cannot replace** (no alternative implementation; app is built on it). Keep with checksum pin (Gradle dependency verification); optionally build from a pinned tag later. |
| 2 | `io.element.android:wysiwyg` | 2.42.1 | Maven Central (assumed) | Rich text editor library (native Rust core + Android wrapper) | https://github.com/matrix-org/matrix-rich-text-editor (`tools/rte/build_rte.sh` builds it locally) | Build from pinned source if provenance is required; otherwise keep with checksum pin. Replaceable only by rewriting the composer. |
| 3 | `io.element.android:wysiwyg-compose` | 2.42.1 | Maven Central (assumed) | Compose UI part of the rich text editor (same version as #2) | same as #2 | Same as #2 (always move with #2). |
| 4 | `io.element.android:opusencoder` | 1.2.0 | Maven Central (assumed) | Opus encoder JNI wrapper for voice messages (`libraries/voicerecorder/impl`) | Upstream repo not identified from static reading; check the POM `scm` | Keep with checksum pin; replace with another Opus encoder if source cannot be located. |
| 5 | `io.element.android:emojibase-bindings` | 1.5.3 | Maven Central (assumed) | Kotlin bindings/data for emojibase emoji set (`app`, `features/messages/impl`) | Upstream repo not identified; data derives from https://github.com/milesj/emojibase | Replace or vendor (data-only, low risk); otherwise keep with checksum pin. |
| 6 | `io.element.android:element-call-embedded` | 0.25.0 | Maven Central (assumed) | Prebuilt Element Call web app bundled as an Android artifact and loaded in a WebView (`features/call/impl`) | https://github.com/element-hq/element-call | **Cannot replace** as a drop-in (call feature depends on it). Keep with checksum pin; building from pinned source is possible but heavy (Node/Vite build, not tested). See `docs/element_call.md`. |
| 7 | `com.github.matrix-org:matrix-analytics-events` | 0.37.0 | JitPack | Generated analytics event definitions (`services/analyticsproviders/api`) | https://github.com/matrix-org/matrix-analytics-events | Replace (drop or vendor generated classes) if analytics is not needed; otherwise pin checksum. JitPack builds on demand, so artifact stability is the weakest of the list. |
| 8 | `element-hq/compound-design-tokens` | branch `main` (unpinned) | `git clone` in `tools/compound/import_tokens.sh` (manual, not part of the Gradle build) | Design tokens, icons and `theme.iife.js` copied into `libraries/compound` | https://github.com/element-hq/compound-design-tokens | Already vendored in-tree. Keep; pin the script to a commit SHA instead of a branch. |
| 9 | `enterprise/` git submodule | n/a | `git@github.com:element-hq/element-android-enterprise.git` (`.gitmodules`) | Private enterprise module; unpopulated in this workspace (FOSS `features/enterprise/impl-foss` is used) | Not public (private repository, access required) | **Cannot replace** if enterprise features are wanted; keep the FOSS implementation otherwise. Do not depend on it in CI without a deploy key (CI already gates on a deploy-key secret). |

**Count: 9 Element-controlled artifacts/sources. Cannot be replaced: 3 (#1, #6, #9).**

## Related, not counted

- `.github/workflows/seventwos-policy-validate.yml` fetches `https://github.com/element-hq/element-x-android.git` for upstream-sync verification (CI only, not a build input).
- `tools/check/check_code_quality.sh` downloads a script from `matrix-org/matrix-dev-tools` (`develop` branch, unpinned) with `wget`; `tools/sas/*` read `matrix-org/matrix-spec` `main`. Both are matrix.org-controlled, not Element, but are unpinned network fetches.
- The Gradle plugin `io.element.android-*` convention plugins are in-tree under `plugins/` (no external download).

## Suggested follow-ups

1. Enable Gradle dependency verification (`gradle/verification-metadata.xml`) covering #1 to #7.
2. Pin script fetches (#8 and the related unpinned ones) to commit SHAs.
3. Verify POM `scm` URLs for #4 and #5 and the actual publishing repository of every `io.element.android` artifact.
