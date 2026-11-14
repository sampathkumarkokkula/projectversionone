# BVM

Privacy-first 1-to-1 messenger for text and photos. Android first, Flutter
codebase reusable for iOS.

Status: **milestone M1 (release APK), feature update v2**. See
[SECURITY.md](SECURITY.md) for the security model and its limits, and
[PRIVACY_POLICY.md](PRIVACY_POLICY.md) for the policy draft.

## Features

### Messaging
| Feature | How it works |
|---|---|
| 1-to-1 text chat | End-to-end encrypted with Olm (Double Ratchet) via the audited vodozemac library. Up to 4000 characters per message. |
| Photos (images only) | Gallery or camera. Before encryption the photo is rotated upright, **stripped of all metadata** (GPS location, camera, time) and shrunk to at most 1600 px / about 300 KB. It travels in encrypted parts of 30 KB through the same relay as messages and is deleted from the server on delivery, at the latest after **7 days** (text: 30 days). No storage bucket, no "save to gallery". |
| Reply to a message | Long-press > Reply. Only the id of the original travels, never a copy of its text, so a reply cannot keep an expired message alive. If the original is gone the quote says "Message no longer available". |
| Delete a message | Long-press > Delete for me (this phone), or Delete for everyone (your own messages; an encrypted delete command removes it from the other phone too). |
| Copy text | Long-press > Copy text. |
| Message search | Search icon in the chat list (all chats) or in a chat (that chat only). Runs only on the phone, over text messages; tap a result to jump to the message. |
| Delivery and read receipts | ✓ sent, ✓✓ delivered, blue ✓✓ read. Not sent for message requests. |
| Offline queue | Messages written offline are encrypted at once and sent when the connection is back. |

### Profile
| Feature | How it works |
|---|---|
| Username | Unique, 3-24 characters `a-z 0-9 _`. The only way people find you (exact match, no browsing). **Can be changed** in Settings, once every 24 hours; contacts see "old is now new". Reserved names (admin, support, bvm, ...) are refused. |
| Profile picture | Settings > tap the picture. Cropped square, 256 px, about 24 KB, no metadata. Sent end-to-end encrypted **only to people you chat with** (not to message requests or blocked users); the server never stores it. |
| Phone number and e-mail | Collected at registration, never shown to anyone. Phone is stored encrypted; e-mail is used for one-time sign-in codes. |

### Auto-delete timers
| Feature | How it works |
|---|---|
| Options | **Off, 1 day, 1 week** (the earlier 1-hour and 5-hour options were removed; chats that already had one keep it until changed). |
| Rules | Applies to messages and photos sent after it is turned on; the countdown starts when a message is sent. Either person can change it and both see a notice. Free version: at most 2 chats with a timer. |
| Enforcement | Expired messages disappear at once on screen, are deleted every 5 s while the app runs and every 15 min when it is closed, and the deletion is relayed to the other phone. |

### Safety
| Feature | How it works |
|---|---|
| Message requests | A chat started by someone new arrives as a **request** (Accept / Block / Report spam). Until you accept or reply, they get no delivery or read receipts and not your profile picture. |
| Block a user | Chat info or the request banner. The server drops everything they send you from then on (they are not told), and queued envelopes from them are deleted. Settings > Blocked users lists and unblocks them, also after moving to a new phone. |
| Report spam | Blocks the user and deletes the chat. Reports contain no messages (end-to-end encryption stays intact). An account reported by **5 different people** (with accounts at least a day old) within 30 days is **suspended**: it cannot send, start chats or be found, and its e-mail address is banned (stored only as a hash). |
| Blocked e-mails and domains | Common throw-away e-mail domains (mailinator, 10minutemail, yopmail, ...) cannot register. The operator can ban more addresses or domains from the SQL editor (see section 2). With the optional Auth hook, banned addresses do not even receive a sign-in code. |
| Delete a chat | Chat info > Delete chat removes it from this phone only. |
| Delete my account | Settings > Delete my account: directory entry, keys, push and inbox tokens, encrypted phone number, e-mail, blocks, reports and waiting envelopes are removed from the server, and everything on the phone is erased. |

### Notifications
| Feature | How it works |
|---|---|
| New-message alerts | **On by default, no setup needed.** They only say "BVM - New message": never who wrote or what, and they are hidden on a secure lock screen. Android 13+ asks for permission after the first unlock (Settings > Notifications shows the state). |
| App open in the background | Alert as soon as the message arrives (Realtime). |
| App closed | A background task asks the server every ~15 minutes, with a random per-phone token and no login session, whether messages wait. Android may delay it in battery saving. |
| Instant alerts when closed (optional) | Configure Firebase Cloud Messaging (section 3, about 10 minutes, free); the push carries no content. |

### Privacy and the app lock
| Feature | How it works |
|---|---|
| Chat history only on the two phones | SQLCipher-encrypted database, key in the Android Keystore. The server is a thin relay + directory + key store and deletes each envelope as soon as it is delivered. |
| App lock | Password on every start; 60 s grace period when switching apps; no biometrics. |
| Secondary (duress) password | Unlocks exactly like the main one, but first silently deletes every chat that has an auto-delete timer, on this phone and (by an encrypted command) on the other person's phone. Settings never reveal whether one is set. "Forgot password" deletes timer chats before the reset. |
| Device hardening | Screenshots and screen recording blocked, blank app-switcher preview, no cloud backup or device transfer, incognito keyboard, no online status or last seen, no contact upload. |
| Safety number | Chat info shows a 60-digit number to compare in person; key changes are announced in the chat. |
| One phone per account | Signing in on a new phone moves the account; the old phone stops sending and receiving and can take it back with an e-mail code. |

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
                   expiry_sweeper, message_service (text, photos, replies,
                   requests, blocks, profile sharing), session_establisher,
                   sync_engine, outbound, timer_policy, payload formats,
                   safety numbers
  data/
    local/         Drift database (SQLCipher, schema v2), key store (Keystore-backed)
    crypto/        OlmCrypto (vodozemac), Argon2idHasher (hashlib)
    media/         ImageProcessor (rotate, strip metadata, shrink; package:image)
    remote/        SupabaseBackend (auth, directory, keys, relay, realtime,
                   blocks, spam reports, username changes)
    push/          local notifications + optional FCM wake-up
    background/    WorkManager task: auto-delete sweep + new-message check
  app/             composition root: bootstrap, services, runtime, account flows,
                   chat actions (block, report, delete chat), account deletion
  presentation/    Riverpod providers; lock, onboarding, chat list, chat, photo
                   viewer, search, chat info, settings, blocked users screens
supabase/
  migrations/      v1 schema + v2 features (RLS policies, RPCs, TTL job, auth hook)
  functions/       push (FCM HTTP v1, FID target), delete-account
  tests/           local PostgreSQL validation (rls_test, rls_v2_test), Deno tests
scripts/           setup-toolchain, env, create-keystore, build-apk, build-aab, test
test/              verifier branch, timer sweep, wipe/relay command, SQLCipher at
                   rest, real vodozemac handshake
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
22.3.3, workmanager 0.10.10, image_picker 1.2.4, image 4.13.0, http 1.6.0
(added 14 Nov 2026). minSdk 26, targetSdk 36.

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
2. **Schema:** in the SQL Editor run both migration files, in this order
   (each: paste > Run):
   1. `supabase/migrations/20261031000000_bvm_init.sql`: tables with RLS, RPCs,
      Realtime publication, 5-minute TTL job, phone-encryption key in Vault.
   2. `supabase/migrations/20261115000000_bvm_v2_features.sql`: username
      changes, blocking, spam reports and suspension, e-mail blocklist, the
      notification inbox check.

   A project that already ran the first file only needs the second. Both are
   safe to run again. With the CLI instead: `npx supabase link --project-ref <ref>`
   then `npx supabase db push`.

   **Optional, recommended:** Authentication > Hooks > *Before User Created* >
   Postgres function `public.bvm_before_user_created`. Banned addresses and
   domains then get no sign-in code at all (otherwise they are refused only at
   registration).

   Operator commands (SQL Editor):
   ```sql
   select private.block_email('someone@example.com');  -- ban one address
   select private.block_email_domain('spam.example');  -- ban a domain
   update public.users set suspended_at = null where username = 'name';  -- lift a suspension
   ```
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
4. **Edge Functions** (`push`, `delete-account`, both needed for "Delete my
   account" and instant notifications):
   `powershell -ExecutionPolicy Bypass -File scripts\deploy-functions.ps1`
   (downloads the Supabase CLI, asks for a personal access token, deploys
   both with `--no-verify-jwt`; they verify the caller's token themselves).
5. **Push (optional):** see section 3. Without the `FCM_SERVICE_ACCOUNT`
   secret the push function answers `push-not-configured` and everything
   else works.
6. Project Settings > API Keys: copy the project URL and the **publishable**
   key into `.env` (copy `.env.example`). Never put the secret key in the app.

## 3. Firebase: instant notifications (optional, free)

Without Firebase, notifications still work (section "Notifications"), but a
closed app can take up to ~15 minutes. With Firebase the phone is woken within
seconds. The push contains only `{"t":"wake"}`: Google never sees who wrote,
what, or any ciphertext.

1. **Create the project:** [console.firebase.google.com](https://console.firebase.google.com)
   > *Create a project* (any name). Google Analytics is not needed: turn it
   off. The free Spark plan needs no card.
2. **Add the Android app:** Project overview > *Add app* > Android. Package
   name **`app.bvm.messenger`** (exactly). Skip the SHA-1 and the SDK steps.
   Download **`google-services.json`**.
3. **Put the app settings into `.env`:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\firebase-env.ps1 C:\Users\<you>\Downloads\google-services.json
   ```
   This fills `FIREBASE_APP_ID`, `FIREBASE_API_KEY`,
   `FIREBASE_MESSAGING_SENDER_ID` and `FIREBASE_PROJECT_ID`. Gradle turns them
   into the Android resources Firebase reads, so the JSON file is not needed in
   the project (keep it out of git).
4. **Create the server key:** Project settings (gear) > *Service accounts* >
   *Generate new private key*. This JSON lets the server send pushes. Treat it
   like a password: never commit it, never put it in the app.
   *Cloud Messaging API (V1)* must be enabled (Project settings > Cloud
   Messaging); it is on by default for new projects.
5. **Deploy the functions and store the key on Supabase:** create a personal
   access token at supabase.com > Account > Access Tokens, then:
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\deploy-functions.ps1 -ServiceAccount C:\Users\<you>\Downloads\<project>-firebase-adminsdk-xxxx.json
   ```
   The script downloads the Supabase CLI into `.toolchain` (no Docker or
   Node.js needed), asks for the token (not saved), deploys `push` and
   `delete-account`, and saves the key as the secret `FCM_SERVICE_ACCOUNT`.
   You can delete both downloaded JSON files afterwards; keep the service
   account only if you may redeploy (you can always generate a new one).
6. **Rebuild and install** (`scripts\build-apk.ps1 -SkipTests`). On first
   unlock, allow notifications.

**Check:** send a message from another account while BVM is closed; "BVM -
New message" should appear within seconds. If it doesn't: Supabase dashboard >
Edge Functions > `push` > Logs. `push-not-configured` means the secret is
missing; an `oauth token request failed` error means the service-account key
is wrong or the FCM API is disabled.

Without the `FIREBASE_*` lines in `.env` the app builds without push and
nothing tries to contact Firebase.

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

`-WithServer` also runs both Supabase migrations twice plus
`supabase/tests/rls_test.sql` (registration, directory privacy, key claims,
relay RLS, TTL clamp, push coalescing, phone encryption, deletion cascades) and
`supabase/tests/rls_v2_test.sql` (blocked domains and the auth hook, username
changes and the 24-hour limit, silent block dropping, inbox token, spam
suspension) on a throw-away local PostgreSQL 17 with Supabase stubs,
type-checks the Edge Functions and runs `supabase/tests/fcm_test.ts` with Deno. It expects the
portable PostgreSQL binaries in `.toolchain\validation\pgsql` and
`deno.exe` in `.toolchain\validation`.

Not covered: the app against a live Supabase project, FCM delivery, and the
UI on a phone. The v2 features (photos, replies, search, blocking, requests,
profile pictures, username changes, notifications) have no Dart unit tests
yet; their server side is covered by `rls_v2_test.sql`.

## Updating an existing install

1. `git pull`
2. Run `supabase/migrations/20261115000000_bvm_v2_features.sql` in the SQL
   Editor (once).
3. Rebuild: `powershell -ExecutionPolicy Bypass -File scripts\build-apk.ps1 -SkipTests`
   and install the APK over the old one (same signing key). The local
   database upgrades itself to schema v2; chats and messages are kept.

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
