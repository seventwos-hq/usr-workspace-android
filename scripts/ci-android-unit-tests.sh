#!/usr/bin/env bash
# Run unit tests only for Gradle modules touched by the PR (BASE_SHA..HEAD) plus a small core set.
# Sized for the Forgejo dev-vm runner: <=5 GB container, ~1h cap (target < 50 min).
set -euo pipefail
BASE_SHA="${BASE_SHA:-}"
CORE_MODULES="libraries/core libraries/architecture libraries/androidutils"
GRADLE_ARGS="${GRADLE_ARGS:---no-daemon --max-workers=2 --stacktrace --console=plain}"

if [ -z "$BASE_SHA" ] || ! git cat-file -e "$BASE_SHA^{commit}" 2>/dev/null; then
  git fetch --no-tags --depth=200 origin "${BASE_REF:-develop}" || true
  BASE_SHA="$(git merge-base HEAD FETCH_HEAD 2>/dev/null || true)"
fi
[ -n "$BASE_SHA" ] || { echo "::error::cannot determine base commit"; exit 1; }
changed="$(git diff --name-only "$BASE_SHA" HEAD)"
echo "Changed files: $(printf '%s\n' "$changed" | grep -c . || true)"

if ! printf '%s\n' "$changed" | grep -qE '\.(kt|kts|java)$|(^|/)(libs\.versions\.toml|gradle\.properties)$|src/[^/]+/(res|AndroidManifest)'; then
  echo "No Kotlin/Java/Gradle changes: skipping unit tests (success)."
  exit 0
fi

modules=""
add() { case " $modules " in *" $1 "*) ;; *) modules="$modules $1";; esac; }
build_wide=0
printf '%s\n' "$changed" | grep -qE '^(build\.gradle\.kts|settings\.gradle\.kts|gradle/|plugins/|gradle\.properties)' && build_wide=1
while IFS= read -r f; do
  [ -n "$f" ] || continue
  d="$(dirname "$f")"
  while [ "$d" != "." ] && [ ! -f "$d/build.gradle.kts" ]; do d="$(dirname "$d")"; done
  [ "$d" != "." ] && add "$d"
done <<< "$changed"
for m in $CORE_MODULES; do [ -f "$m/build.gradle.kts" ] && add "$m"; done

tasks=""; tested=""; skipped=""
for m in $modules; do
  if [ ! -d "$m/src/test" ]; then skipped="$skipped $m(no-tests)"; continue; fi
  if [ "$m" = "app" ]; then t=":app:testGplayDebugUnitTest"
  else
    p=":$(echo "$m" | tr / :)"
    if grep -qE 'kotlin\.jvm|java-library|kotlin\("jvm"\)|libs\.plugins\.kotlin\.jvm' "$m/build.gradle.kts" && ! grep -q 'android' "$m/build.gradle.kts"; then t="$p:test"; else t="$p:testDebugUnitTest"; fi
  fi
  case "$m" in tests/konsist*) skipped="$skipped $m(heavy)"; continue;; esac
  tasks="$tasks $t"; tested="$tested $m"
done
[ "$build_wide" = 1 ] && echo "NOTE: build-wide files changed; only changed+core modules tested here, full suite runs on GitHub Actions."
echo "Modules tested:${tested:- none}"
echo "Modules skipped:${skipped:- none}"
[ -n "$tasks" ] || { echo "Nothing to test."; exit 0; }
echo "Gradle tasks:$tasks"
# shellcheck disable=SC2086
./gradlew $tasks --continue $GRADLE_ARGS
