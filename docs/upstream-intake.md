# Upstream intake (Element X Android -> Seventwos Workspace Android)

How to pull a new Element X Android release into this fork safely. Adapted from the desktop template (usr-workspace-desktop `docs/upstream-intake.md`).

Read `AGENTS.md` and `.seventwos/policy.yml` first; `.seventwos/ledger.jsonl` is append-only. Upstream sync rules live in `.seventwos/` (see `.seventwos/README.md`).

## Procedure

1. Fetch upstream tag (unverified; add remote once):
   `git remote add upstream <element-x-android-upstream-url>` ; `git fetch upstream --tags` (unverified)
2. Branch off develop:
   `git fetch origin && git checkout -b intake/<upstream-tag> origin/develop` (unverified)
3. Merge the tag: `git merge <upstream-tag>` (unverified). Resolve conflicts keeping Seventwos names/ids/config. The `io.element.android.*` package namespace is kept as-is (INV-IDENTITY-002); accept new upstream packages unchanged.
4. Re-apply and verify branding:
   - `scripts/brand-guard.sh` must print `brand-guard: OK` (run on current develop: see PR description for result).
   - New legitimate matches only: justify, then `scripts/brand-guard.sh --update` (regenerates baseline in `.brand-guard-allowlist`) and review the diff (unverified). Prefer rebranding over raising a baseline.
   - Check `APPLICATION_ID` (`org.seventwos.workspace`) and `URL_WEBSITE` in `plugins/src/main/kotlin/config/BuildTimeConfig.kt`, and the applicationId assignment in `app/build.gradle.kts`.
5. Quick checks (all unverified; Gradle needs JDK + Android SDK, see `docs/_developer_onboarding.md`):
   - `python3 -m unittest scripts/seventwos/validate_seventwos_test.py -v` (unverified)
   - `python3 scripts/seventwos/validate_seventwos.py --base-ref origin/develop` (unverified)
   - `./gradlew :app:compileGplayDebugKotlin` (unverified)
   - `./gradlew :app:testGplayDebugUnitTest testDebugUnitTest -x :tests:konsist:testDebugUnitTest` (unverified)
   - `./gradlew :tests:konsist:testDebugUnitTest` (unverified)
   - `./gradlew ktlintCheck detekt` (unverified)
   - Only `documentation/` is OKF-validated (`scripts/okf/validate_okf_markdown.py --changed`, unverified); files in `docs/` need no frontmatter.

6. Push `intake/<upstream-tag>` and open a PR into `develop`. Do not merge without review; do not tag or release.

## Invariants (must hold after every intake)

- Application ID stays `org.seventwos.workspace` (INV-IDENTITY-001), never `io.element.android.x`.
- Default homeserver is `workspace.seventwos.org` (`AccountProviderDataSource`, `DefaultLoginIntentResolver.LOGIN_HINT_HOST`, `BuildTimeConfig.URL_WEBSITE`).
- `scripts/brand-guard.sh` passes.
- No `element.io` / `riot.im` / `app.element.*` URLs outside `.brand-guard-allowlist`.
- Seventwos invariants in `.seventwos/invariants.yml` still hold; weakening one needs review and a ledger entry.
- Ledger entries are never edited, reordered or removed.
