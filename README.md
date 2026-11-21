# Seventwos Workspace for Android

Seventwos Workspace for Android is the native Android client for the Seventwos workspace. It is built on top of a fork of [Element X Android](https://github.com/element-hq/element-x-android) and is being evolved for people and agents to communicate and collaborate over [Matrix](https://matrix.org/).

The project retains Element X's native-client approach: Jetpack Compose over the [Matrix Rust SDK](https://github.com/matrix-org/matrix-rust-sdk), exposed to Kotlin through its bindings. The shared Rust core provides Matrix synchronisation, local state, and end-to-end encryption while the application remains native to Android.

## Status

This repository is in transition from its Element X foundation to a separately authored Seventwos application layer.

The current code includes inherited Element X Android code, branding, and configuration. This fork redistributes that code under the GNU Affero General Public License v3 and must not be represented as an independently authored Seventwos implementation. The transition will replace the inherited application layer with Seventwos code while retaining the native-client architecture and the Apache-2.0 Matrix Rust SDK.

## Architecture

The intended Android implementation includes:

- Kotlin and Jetpack Compose.
- Matrix Rust SDK integration through Kotlin bindings.
- Client-side Matrix end-to-end encryption.
- Secure credential storage in the Android Keystore.
- Background synchronisation.
- Android push notifications for encrypted messages.

Element X is the upstream foundation and architectural reference for this workspace, not the target product identity.

## Repository scope

This is the product repository for Seventwos Workspace for Android. It is the source of truth for the Android application code, Android platform integrations, build and test configuration, and release preparation.

Changes in this repository should directly support the Android client. Shared services and cross-platform product material are maintained separately; the origins and licensing of upstream-derived code are documented below.

## Fork separation and where we work

To keep selective upstream synchronisation with `element-hq/element-x-android` tractable, the repository separates the **inherited upstream foundation** from the **Seventwos layer** and tracks the boundary in [`.seventwos/`](.seventwos/README.md) (`path-map.yml`, `invariants.yml`, `state.yml`, `ledger.jsonl`). `scripts/seventwos/validate_seventwos.py` enforces the structural integrity and anti-tamper rules of the `.seventwos/` policy metadata, while upstream sync reviews verify that product behavior and invariants are preserved.

### 1. Upstream compatibility boundary (preserve as-is)

- **Package namespace & Gradle convention plugins (`compatibility_sensitive_identifier`, `INV-IDENTITY-002`)**: Keep the inherited `io.element.android.*` Kotlin/Java package prefix, `namespace = "io.element.android.x"` in `app/build.gradle.kts`, and `io.element.*` Gradle convention plugin IDs under `plugins/`. Preserving these identifiers avoids tree-wide rename conflicts during upstream syncs and keeps Matrix Rust SDK bindings and `ignoreDependencies(groupId = "io.element.android")` working unchanged.
- **Private upstream submodule (`out_of_scope`, `INV-SUBMODULE-001`)**: `enterprise/` is a private upstream submodule excluded from upstream assessment and sync tooling (`INV-SUBMODULE-001`).

### 2. Where Seventwos work lives (the Seventwos layer)

- **New Seventwos features and services (preferred extension mechanism)**:
  - Add new product capabilities as self-contained Gradle modules under `features/<feature>/{api,impl}` or `services/<service>/{api,impl}` (auto-included by `settings.gradle.kts`) and bind them via Metro dependency injection rather than rewriting inherited Element X feature modules in place.
- **Application shell, DI bindings, startup & navigation (`product_divergence` in `.seventwos/path-map.yml`)**:
  - `app/src/main/kotlin/io/element/android/x/SeventwosWorkspaceApplication.kt` — Seventwos `Application` entrypoint.
  - `app/src/main/kotlin/io/element/android/x/di/` (`AppBindingContainer.kt`, `ApplicationBindings.kt`) — root Metro DI bindings where Seventwos implementations override or extend upstream bindings.
  - `app/src/main/kotlin/io/element/android/x/initializer/` (`PlatformInitializer.kt`) — startup initialisers.
  - `appnav/src/main/kotlin/io/element/android/appnav/intent/` (`IntentResolver.kt`) — deep-link and intent routing.
- **Product identity, branding & endpoint configuration (`branding` in `.seventwos/path-map.yml`, `INV-IDENTITY-001/003`, `INV-ENDPOINT-001/002`, `INV-TELEMETRY-001`)**:
  - `plugins/src/main/kotlin/config/BuildTimeConfig.kt` — sets `APPLICATION_ID = "com.seventwos.workspace"` and `APPLICATION_NAME = "Seventwos Workspace"`, sources push and telemetry/crash-reporting endpoints from `SEVENTWOS_ANDROID_*` build-time environment variables (fail-closed), and keeps map/legal URLs as Seventwos-controlled constants (`https://workspace.seventwos.com`) or `null` placeholders (`INV-ENDPOINT-002`; never hardcode upstream Element URLs).
  - `appconfig/src/main/kotlin/io/element/android/appconfig/ApplicationConfig.kt` — user-facing product names (`Seventwos Workspace`).
  - `appicon/` and `fastlane/` — application icons and store metadata.
- **Upstream sync policy & ledger (`seventwos_policy_system`)**:
  - `.seventwos/` and `scripts/seventwos/` — whenever a Seventwos change introduces a new divergent path inside the inherited tree or a new product/security invariant, record it in `.seventwos/path-map.yml` and `.seventwos/invariants.yml` so upstream sync reviews preserve it.

## Provenance and licence

This repository began as a fork of Element X Android and is now maintained as Seventwos Workspace for Android.

Copyright (c) 2025 Element Creations Ltd.

Copyright (c) 2022 - 2025 New Vector Ltd.

These upstream copyright notices are retained in recognition of the work on which this fork is based.

We license the repository-owned code under the GNU Affero General Public License v3 only. See [LICENSE](LICENSE) for the applicable terms. Third-party dependencies remain under their respective licences.

Our modifications and newly authored repository code use AGPL-3.0-only. When we distribute a modified version or make one available for users to interact with over a network, we provide the corresponding source as required by the AGPL.

