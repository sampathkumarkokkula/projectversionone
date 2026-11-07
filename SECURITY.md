# BVM security model

This document describes what BVM protects, how, and where the protection ends.
It reflects the code in this repository (milestone M1, Android).

## 1. End-to-end encryption

### Library choice

The brief asked to evaluate `libsignal_protocol_dart` and Famedly's
`dart-vodozemac` and to pick the actively maintained one. State in October 2026:

| | libsignal_protocol_dart 0.8.2 | vodozemac 0.9.0 / flutter_vodozemac 0.9.0 |
|---|---|---|
| Protocol | Signal: X3DH + Double Ratchet | Olm: triple-DH handshake + Double Ratchet |
| Implementation | Pure-Dart port of the (retired) libsignal-protocol-java | Dart bindings (flutter_rust_bridge) to vodozemac, Matrix's Rust implementation |
| Audit | No public audit of the Dart port | vodozemac audited by Least Authority (2022) |
| Activity | Last release June 2026, last commit June 2026 | Last release 19 Oct 2026; vodozemac core commits in the last week |
| License | GPL-3.0 | Bindings AGPL-3.0, vodozemac core Apache-2.0 |
| Android build | Pure Dart | Compiles the Rust crate (Rust toolchain required; `scripts/setup-toolchain.ps1` installs it) |

**Chosen: vodozemac.** It is the more actively maintained of the two, its core
is independently audited, and its primitives are memory-safe Rust from the
dalek and RustCrypto projects instead of pure-Dart curve arithmetic. BVM uses
only its high-level API (Account, Session, Ed25519 signatures, encrypted
pickles); no cryptographic primitive is implemented in this repository.

Also noted: `libsignal_dart` (a community wrapper around Signal's official Rust
`libsignal`, AGPL-3.0) is active but very new, with a single maintainer.

> **License decision for the product owner.** Both candidates are copyleft.
> With dart-vodozemac (AGPL-3.0) the distributed app must be offered under
> AGPL-3.0 with source available, and App Store distribution of AGPL code is
> legally contested. Before a paid version or the iOS release, either accept
> open-sourcing BVM, obtain a commercial license, or replace the bindings
> with in-house bindings to the Apache-2.0 vodozemac core.

### How Olm maps to the brief's "X3DH + Double Ratchet"

* Each phone has an Olm account: a Curve25519 identity key and an Ed25519
  signing key.
* At registration it uploads 50 one-time keys and one fallback key, each
  signed with the Ed25519 key (`bvm-key-v1:<key>`). The fallback key plays the
  role of Signal's signed prekey: it is used only when the one-time keys run
  out. The app tops the one-time keys up when fewer than 20 remain.
* To start a chat, the sender claims one key through `claim_one_time_key`
  (atomically deleted on the server), verifies its signature against the
  peer's Ed25519 key and creates an outbound Olm session (triple
  Diffie-Hellman). From then on the Double Ratchet provides forward secrecy
  and post-compromise security, as in Signal.
* The recipient creates the inbound session from the first (pre-key) message;
  vodozemac removes the used one-time key and checks the identity key.
* Olm session config v1 (the audited, libolm-compatible default) is used.

### Authentication of keys

Identity keys come from the server, so a malicious server could substitute
them. BVM pins each peer's keys on first contact (trust on first use), shows
"Your security code with X changed" when they change, and shows a 60-digit
**safety number** (Chat info) derived from both Ed25519 keys. Comparing it in
person or on a call detects a key substitution.

### Message format

Inside the encryption: a JSON payload (`text`, `receipt`, `delete`, `wipe`,
`timer`, `hello`) padded with spaces to a multiple of 256 bytes. Outside: the
Olm message type and ciphertext in `relay.ciphertext`.

### What the server can see (metadata)

The relay is end-to-end encrypted but not anonymous. The server sees: sender
and recipient user ids, the envelope type column (`message`, `receipt`,
`delete`, `timer_change`), padded ciphertext size, timestamps, IP addresses
(Supabase logs), and when push wake-ups are sent. A duress wipe travels as type
`delete`, the same type as a routine relayed timer deletion. There is no sealed
sender and no post-quantum key agreement (Signal has both).

## 2. Data at rest on the phone

* **Database:** SQLite with SQLCipher (community edition bundled by
  `package:sqlite3` build hooks, `source: sqlcipher`), opened with a random
  256-bit raw key. The key is generated on first launch and kept in
  `flutter_secure_storage` (AES-GCM, key wrapped by the Android Keystore). The
  app refuses to run if SQLCipher is not linked. `secure_delete` overwrites
  deleted rows; wipes also checkpoint and truncate the WAL file.
* **Olm state:** the pickled account and sessions are additionally encrypted
  with a second random 256-bit key (the "pickle key") from secure storage.
* **Supabase session:** stored in secure storage, not in SharedPreferences.
* **Backups:** `allowBackup="false"`, full-backup exclusions and
  data-extraction rules exclude every domain from cloud backup and from
  device-to-device transfer.
* A unit test (`test/encrypted_database_test.dart`) checks that the database
  file contains no plaintext and does not open with a wrong key.

## 3. The app lock (main and secondary password)

* The server authenticates the device session with an e-mail one-time code.
  The two passwords are a purely local lock and never leave the phone.
* Both passwords are stored as Argon2id verifiers (PHC strings, 16-byte random
  salt, 19 MiB, 2 passes, 1 lane = the OWASP recommendation) via the pure-Dart
  `hashlib` package, checked against RFC 9106 vectors upstream. The parameters
  live in each PHC string and can be raised later.
* **Two slots always exist.** Without a secondary password, the second slot
  holds the verifier of a random 256-bit password nobody knows, so the stored
  data looks the same whether or not one is set.
* **Every unlock attempt computes both hashes** (in two isolates), so main,
  secondary and wrong passwords cost the same time. The comparison is
  constant-time. A unit test asserts both verifiers run for every attempt.
* After 5 wrong attempts, waiting times start at 30 s and double.
* The password is asked on every cold start. Returning within 60 s of leaving
  the app does not lock; after 60 s the app locks (also while in the
  background, via a timer). There is no biometric unlock.

### Secondary (duress) password

Unlocking with it is indistinguishable on screen from a normal unlock. Before
the chat list is shown, in one database transaction, BVM:

1. deletes the full conversation (all messages, including ones sent before the
   timer was enabled) of **every chat that has an auto-delete timer**;
2. drops that chat's unsent messages and pending deletes, and records a wipe
   time so messages sent before it that arrive later are discarded;
3. queues an end-to-end-encrypted wipe command for each such peer in the local
   outbox.

The chat entries and their timers stay, so the list looks like chats whose
messages simply expired. The outbox is sent as soon as the relay is reachable;
the server holds the command until the peer's app collects it (up to 30 days).
The peer's app deletes the same conversation silently. No banner, toast,
notification or delay is shown on either phone. Wipe commands do not trigger a
push notification.

Settings never reveal whether a secondary password exists. Inside a session
that was unlocked with the secondary password, the settings act on what the
person holding the phone believes are "the" passwords:

* "Change password" changes the secondary password (the main one keeps working).
* "Secondary password" changes (or, if left empty, replaces with a random
  value) the **main** password. The owner then recovers with "Forgot password".

### Forgot password

Before anything else, "Forgot password" permanently deletes every chat that has
an auto-delete timer on this phone (local only, no relay), so a reset cannot be
used to get around the secondary password. Then the account e-mail receives a
one-time code, and new passwords are set.

## 4. Auto-delete timers

* Options: Off, 1 hour, 5 hours, 1 day, 1 week. Free version: at most 2 chats
  with a timer at a time (enabling a third shows the upsell). A timer set by
  the peer is always honoured, even beyond the local limit: refusing it would
  keep their messages longer than they asked.
* The timer value at sending time travels with each message. The countdown
  starts when the message is sent (receivers use the earlier of the sender's
  timestamp and their own clock). Messages sent before a timer was enabled
  never expire.
* Enforcement: expired messages are hidden immediately; a sweep deletes them
  every 5 seconds while the app runs and every 15 minutes via WorkManager
  while it is closed. The sender also relays an encrypted delete command for
  its expired messages, which corrects a peer whose clock is behind.
* On the server, an undelivered timed message expires with its timer.

## 5. Other hardening

* `FLAG_SECURE` blocks screenshots, screen recording and casting; recents
  thumbnails are blank (`setRecentsScreenshotEnabled(false)` on Android 13+),
  plus an in-app cover while the app is inactive.
* All text fields ask the keyboard for incognito mode
  (`IME_FLAG_NO_PERSONALIZED_LEARNING`), no suggestions, no autocorrect, no
  autofill. No `PROCESS_TEXT` integrations in text-selection menus.
* No presence, no last seen, no contact upload. Discovery is by exact username
  only; the directory cannot be listed (RLS + RPCs).
* Push: data-only FCM message `{"t":"wake"}`; the phone shows "BVM - New
  message", hidden on the lock screen. FCM auto-init, analytics and the
  advertising id are disabled.
* Release builds: Dart obfuscation, R8 shrinking, `android.util.Log` calls
  stripped, `debugPrint`/`print` silenced, TLS only.
* Server: Row Level Security on every table, SECURITY DEFINER RPCs with an
  empty `search_path`, nothing executable by `anon`, phone numbers encrypted
  with pgcrypto using a key held in Supabase Vault, relay rows clamped to a
  30-day TTL and purged by pg_cron.

## 6. Known limits

* **A second camera can photograph the screen.** FLAG_SECURE only stops
  software capture.
* **A rooted or compromised phone weakens every on-device protection**:
  malware with root can read memory, the Keystore-protected keys, keystrokes
  and the screen. Argon2id verifiers can then be attacked offline; the
  parameters are a trade-off with unlock time in pure Dart.
* **Remote deletion relies on the peer running the real app.** A modified
  client, a backup of the peer's phone, or the peer's own screenshots (on
  other devices) can keep messages. Wipe commands are delivered only when the
  peer's app next connects (within 30 days).
* The server sees metadata (section 1). Supabase and Google (FCM) are trusted
  not to log beyond their standard logs.
* The keyboard incognito flag is a request; a third-party keyboard can ignore it.
* Dart strings (typed passwords, decrypted text in memory) cannot be wiped
  reliably from memory.
* One phone per account. Signing in on a new phone creates new keys; history
  never moves and contacts see a security-code change.
* Username lookups and one-time-key claims are not rate limited yet; key
  claiming can be used to exhaust one-time keys (the fallback key keeps
  sessions possible).
* If the Keystore entry is lost, the database cannot be decrypted and the app
  starts over.

## 7. Reporting a vulnerability

Send details to [security contact e-mail]. Please do not open public issues
for security problems.
