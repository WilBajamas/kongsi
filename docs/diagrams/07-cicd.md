# 07 · CI/CD pipeline

**Type:** sequence — a commit's journey across two hosts split by responsibility:
GitHub Actions asks *"is the code good?"*, Bitrise + fastlane *"get the good build
onto a tester's phone."*
**Source:** [technical-summary §12](../technical-summary.md) · [.github/workflows/ci.yml](../../.github/workflows/ci.yml) · [bitrise.yml](../../bitrise.yml) · [Fastfile](../../android/fastlane/Fastfile)

```mermaid
sequenceDiagram
    autonumber
    actor Dev
    participant GH as GitHub
    participant GA as GitHub Actions · CI (is the code good?)
    participant BR as Bitrise · CD (get it on a device)
    participant FL as fastlane
    participant FAD as Firebase App Distribution

    Note over Dev,GA: — every PR / push to main or develop —
    Dev->>GH: open PR / push
    GH->>GA: trigger CI (concurrency: cancel superseded runs)
    GA->>GA: verify — pub get · enable-native-assets ·<br/>format · analyze --fatal-infos · test
    par after verify passes (needs: verify)
        GA->>GA: build-android · debug APK, dev flavor (ubuntu)
    and
        GA->>GA: build-ios · compile-only, no codesign (macOS) — proves the Swift stub, see 06
    end
    GA-->>GH: green check gates merge
    opt any step failed
        GA->>GH: upload golden-failure diff images as artifact
    end

    Note over Dev,FAD: — only on push to develop (trigger_map) —
    Dev->>GH: merge → push to develop
    GH->>BR: trigger workflow: distribute_staging
    opt SSH key present
        BR->>BR: activate-ssh-key — skipped: Bitrise clones via GitHub App token
    end
    BR->>GH: git-clone clone_depth = -1 · FULL history
    Note right of BR: full clone so build number = git rev-list --count HEAD<br/>isn't undercounted (ADR-022, CI-agnostic across both hosts)
    BR->>BR: decode base64 secrets → config/staging.json + firebase service account
    BR->>BR: flutter build apk --release --flavor staging<br/>--build-number=$(commit count) --build-name=0.1.0 · debug-signed for now
    BR->>FL: bundle exec fastlane distribute_staging
    FL->>FAD: firebase_app_distribution — upload APK to group "internal"
    FAD-->>Dev: build lands on tester's phone
```

**Reading it**

- **Two hosts, split by responsibility.** Actions is free + hand-written — the right
  place to *learn* CI and gate every PR. Release signing/store delivery lean on
  Mac-dependent tooling a no-Mac dev can't run locally — that's Bitrise's job.
- **The build number is why the clone is full** (`clone_depth: -1`): it's the git
  commit count, chosen because it's identical whichever host builds. A shallow clone
  would undercount it.
- **FAD is last-mile only** — it distributes a *built* APK; it does **not** need the
  Firebase SDK in the app (`firebase_core`/FCM are runtime concerns, added later).

**War story — auth vs authz (the sharpest lesson).** FAD kept returning "permission
denied." The key was **valid** — authentication *succeeded*. The failure was
**authorization**: a valid key for the *wrong service account* on the *wrong GCloud
project*. Fix: a service account with `roles/firebaseappdistro.admin`, API enabled,
on the correct project. Recognising *which* of the two is failing from the error is
the skill.

**Three more setup traps:** Bitrise *Release Management* ≠ *CI* (only CI builds from
source) · the `activate-ssh-key` step must be `run_if` SSH-present or it fails when
cloning via App token · config-as-code — `bitrise.yml` lives in the repo, reviewable.

**Seams:** the macOS `build-ios` job compiles the connectivity Swift stub → `06`.
