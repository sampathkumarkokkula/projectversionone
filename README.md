# BVM

Privacy-first 1-to-1 text messenger (MVP). Android first, Flutter codebase
reusable for iOS.

* End-to-end encrypted with Olm (Double Ratchet) via the audited vodozemac library.
* Chat history only on the two phones, in an SQLCipher database. The server is
  a thin relay + username directory + public-key store + push trigger and
  deletes each encrypted envelope as soon as it is delivered.
* Local app lock with a main password and an optional secondary (duress)
  password that silently wipes every chat with an auto-delete timer, on both
  phones.
* Auto-delete timers (Off / 1 h / 5 h / 1 day / 1 week, at most 2 timer chats
  in the free version).
* Screenshots blocked, no backups, incognito keyboard, no presence, no contact
  upload, content-free push.

Status: **milestone M1 (release APK)**. See [SECURITY.md](SECURITY.md) for the
security model and its limits, and [PRIVACY_POLICY.md](PRIVACY_POLICY.md) for
the policy draft.

## Costs

| Item | Cost |
|---|---|
| Supabase free tier (Postgres, Auth, Realtime, Edge Functions, Vault, pg_cron) | $0, no card. Free projects pause after 7 days without activity; un-pause in the dashboard. |
| E-mail for one-time codes | $0 with a free SMTP account (see below). Supabase's built-in mailer only sends to your own team's addresses, 2 per hour. |
| Firebase Cloud Messaging (optional push) | $0, no card (Spark plan) |
| Google Play developer account (M2) | **US$25 one-time** registration fee |
| Apple Developer Program (M3, iOS) | **US$99 per year**, plus a Mac with Xcode |
| Phone verification via WhatsApp OTP (later) | **Paid per message** in most countries (WhatsApp Business "authentication" category). Not enabled. |

## Repository layout

```
lib/
  core/            env (dart-define config), clock, ids, debug-only logging
  domain/          use cases + ports: lock_service (two passwords), wipe_service,
                   expiry_sweeper, message_service, sync_engine, outbound,
                   timer_policy, payload formats, safety numbers
  data/
    local/         Drift database (SQLCipher), key store (Keystore-backed)
    crypto/        OlmCrypto (vodozemac), Argon2idHasher (hashlib)
    remote/        SupabaseBackend (auth, directory, keys, relay, realtime)
    push/          FCM wake-up + generic local notification
    background/    WorkManager auto-delete sweep
  app/             composition root: bootstrap, services, runtime, account flows
  presentation/    Riverpod providers, lock/onboarding/chat/settings screens
supabase/
  migrations/      schema, RLS policies, RPCs, Realtime publication, TTL job
  functions/       push (FCM HTTP v1, FID target), delete-account
scripts/           setup-toolchain, env, create-keystore, build-apk, build-aab, test
test/              verifier branch, timer sweep, wipe/relay command, SQLCipher at rest
```

The domain services persist through the Drift database directly (inside
transactions) instead of separate repository interfaces, so a ratchet step,
the message it encrypted and the outbox entry are always committed together.
Crypto, relay and directory are behind interfaces (`domain/ports.dart`) and
are replaced by fakes in the tests.

**State management: Riverpod**, because it gives compile-time-safe dependency
injection plus reactive state without `BuildContext`, and any provider can be
overridden in tests.

## Versions (verified 31 Oct 2026)

Flutter 3.47.9 (Dart 3.13.7), AGP 9.1, Gradle 9.3.1, JDK 17, Android SDK 36,
NDK 28.2.13676358, Rust 1.99.1. Packages: drift 2.35.3, sqlite3 3.8.0
(SQLCipher via build hooks; `sqlcipher_flutter_libs` is end-of-life),
flutter_secure_storage 11.2.0, supabase_flutter 2.18.3, vodozemac /
flutter_vodozemac 0.9.0, hashlib 2.4.2, flutter_riverpod 3.4.3,
firebase_core 5.1.0, firebase_messaging 17.0.1, flutter_local_notifications
22.3.3, workmanager 0.10.10. minSdk 26, targetSdk 36.

## 1. Toolchain (Windows, no admin rights)

```powershell
cd C:\dev\BVM
powershell -ExecutionPolicy Bypass -File scripts\setup-toolchain.ps1
```

Installs into `C:\dev\BVM\.toolchain` (git-ignored, about 8 GB): Temurin JDK 17,
Flutter 3.47.9 (SHA-256 checked), Android command-line tools, platform 36,
build-tools 36.0.0, NDK 28.2, and Rust (rustup, GNU host toolchain + Android
targets; needed to compile vodozemac). Nothing is added to the system PATH;
rustup registers itself under "Installed apps" for the current user. Every
script dot-sources `scripts\env.ps1`, which points JAVA_HOME, ANDROID_HOME,
PUB_CACHE, GRADLE_USER_HOME, RUSTUP_HOME and CARGO_HOME at that folder. Run
`. .\scripts\env.ps1` to use `flutter` in your own shell. Deleting
`.toolchain` removes all of it.

Keep the project outside OneDrive (sync corrupts Gradle/Cargo outputs).

## 2. Supabase (free tier)

1. Create a project at supabase.com (no card needed).
2. **Schema:** SQL Editor > paste `supabase/migrations/20261031000000_bvm_init.sql` > Run.
   With the CLI instead: `npx supabase link --project-ref <ref>` then `npx supabase db push`.
   The script enables pgcrypto, Vault and pg_cron, creates the tables with RLS,
   the RPCs, the Realtime publication and the 5-minute TTL job, and generates
   the phone-encryption key inside Vault.
3. **E-mail one-time codes:**
   * Authentication > Sign In / Providers > Email: enabled (default).
   * Authentication > Emails > SMTP Settings: configure a free SMTP sender
     (for example a Gmail account with an app password: `smtp.gmail.com`,
     port 587; or Brevo's free plan). Without custom SMTP, Supabase only
     delivers to your organisation's team members (fine for a first test).
   * Authentication > Emails > Templates: in **Magic Link** and **Confirm
     signup**, include the code, for example `<p>Your BVM code: {{ .Token }}</p>`,
     and remove the link if you like. New free projects can edit templates only
     after custom SMTP is configured. The app accepts 6-10 digit codes.
4. **Edge Functions** (`push`, `delete-account`): with the CLI,
   `npx supabase functions deploy push --no-verify-jwt` and
   `npx supabase functions deploy delete-account --no-verify-jwt`
   (both verify the caller's token themselves), or create them in the dashboard
   (Edge Functions > Deploy a new function) with the same names and paste
   `index.ts` together with `supabase/functions/_shared/supabase.ts`.
5. **Push (optional):** Edge Functions > Secrets: add `FCM_SERVICE_ACCOUNT`
   with the JSON of a Firebase service account (Firebase console > Project
   settings > Service accounts > Generate new private key). Without it the
   push function answers `push-not-configured` and everything else works.
6. Project Settings > API Keys: copy the project URL and the **publishable**
   key into `.env` (copy `.env.example`). Never put the secret key in the app.

## 3. Firebase (optional push)

Create a Firebase project (Spark plan), add an Android app with package
`app.bvm.messenger`, and copy app id, API key, sender id and project id from
Project settings into `.env`. No `google-services.json` is needed: Gradle
turns these values into the Android resources Firebase reads. Leave them empty
to build without push.

## 4. Build the release APK (M1)

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build-apk.ps1
```

The script creates the upload keystore on first use
(`scripts\create-keystore.ps1`: RSA 4096 in `.secrets\upload-keystore.jks`, a
random password in `android\key.properties`, both git-ignored), regenerates the
Drift code, runs the tests, builds an obfuscated, R8-shrunk release APK with
`--dart-define-from-file=.env`, and writes `dist\bvm-1.0.0-1-release.apk` plus
a `.sha256` file. **Back up `.secrets\` and `android\key.properties` offline**;
updates must be signed with the same key. Use `-SplitPerAbi` for smaller
per-architecture APKs, `-SkipTests` to skip the tests.

Without `.env`, the APK builds but opens a "not configured" screen.

## 5. Install

* **adb:** enable Developer options > USB debugging on the phone, connect it, then
  `.\.toolchain\android-sdk\platform-tools\adb.exe install -r dist\bvm-1.0.0-1-release.apk`
* **Direct transfer:** copy the APK to the phone (USB, cable, local share), open
  it in Files and allow "Install unknown apps" for that app when Android asks.
  Compare the SHA-256 from the `.sha256` file if the transfer path is not trusted.

Android 8.0 (API 26) or newer.

## 6. Tests

```powershell
powershell -ExecutionPolicy Bypass -File scripts\test.ps1 [-WithOlm] [-WithServer]
```

Runs `flutter analyze` and the Dart unit tests:

* `test/lock_service_test.dart`: the password-verifier branch (main vs
  secondary vs wrong, both verifiers computed on every attempt, decoy slot,
  throttling, settings behaviour in both modes).
* `test/expiry_sweeper_test.dart`: the timer-expiry sweep (timer applies only
  to later messages, expiry boundaries, relayed deletes, received timed
  messages, the 2-chat limit).
* `test/wipe_relay_test.dart`: the wipe/relay command between two simulated
  phones (offline queue, relay, execution on the peer, late messages dropped,
  local-only reset wipe, peer timer changes, receipts).
* `test/encrypted_database_test.dart`: SQLCipher encryption at rest.
* `test/olm_crypto_test.dart`: the real vodozemac handshake and ratchet,
  replay rejection, forged one-time-key signatures, fallback keys, pickle
  encryption. `-WithOlm` compiles vodozemac for the PC (needs the Rust
  toolchain) so these run; otherwise they are skipped.

`-WithServer` also runs the Supabase migration twice plus
`supabase/tests/rls_test.sql` (registration, directory privacy, key claims,
relay RLS, TTL clamp, push coalescing, phone encryption, deletion cascades) on
a throw-away local PostgreSQL 17 with Supabase stubs, type-checks the Edge
Functions and runs `supabase/tests/fcm_test.ts` with Deno. It expects the
portable PostgreSQL binaries in `.toolchain\validation\pgsql` and
`deno.exe` in `.toolchain\validation`.

Not covered: the app against a live Supabase project, FCM delivery, and the
UI on a phone.

## 7. Next milestones

* **M2, Google Play:** `scripts\build-aab.ps1`. See [docs/PLAY_RELEASE.md](docs/PLAY_RELEASE.md)
  (closed test with 12 testers for 14 days for new personal accounts, hosted
  privacy policy, Data safety answers, account-deletion web link).
* **M3, iOS:** see [docs/IOS.md](docs/IOS.md). Needs macOS, Xcode and the Apple
  Developer Program.

## Licensing

BVM depends on `vodozemac` (AGPL-3.0 Dart bindings over an Apache-2.0 core).
Distributing the app therefore triggers AGPL obligations. This needs a decision
before a paid version or App Store release; see SECURITY.md section 1.
