# Kongsi

Offline-first shared-expense app (Flutter), built by hand as a learning and
senior→lead showcase.

## Getting started

**Prerequisite:** [FVM](https://fvm.app) — it manages the pinned Flutter SDK.

Clone the repo, then from the root run the one-time setup for your platform:

```powershell
./tool/bootstrap.ps1     # Windows
```

```sh
./tool/bootstrap.sh      # macOS / Linux
```

Both install the pinned Flutter SDK, enable native assets (needed by sqlite3),
fetch packages, and seed `config/dev.json` from the example.

Then run the dev flavor on a connected device or emulator:

```sh
fvm flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json
```

> The example config points at a placeholder backend, so the app **runs and
> works locally** out of the box — only cloud sync needs real Supabase
> credentials filled into `config/dev.json`.

<details>
<summary>Prefer to run the steps by hand?</summary>

```sh
fvm install
fvm flutter config --enable-native-assets   # sqlite3 native lib
fvm flutter pub get
cp config/dev.example.json config/dev.json
fvm flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json
```
</details>

## Flavors

`dev` / `staging` / `prod`, each with its own entrypoint (`lib/main_<flavor>.dart`)
and config (`config/<flavor>.json`). Staging builds auto-distribute to Firebase
App Distribution on push to `develop`.

## Docs

- [Architecture Decision Records](docs/adr/README.md)
- [Definition of Done](docs/definition-of-done.md)
