# Going live checklist

Work through this before giving BVM to people outside your test group. Items
marked **(you)** need a decision or an account only you have.

## 1. Decisions

- [ ] **(you) Licence.** `vodozemac` (the encryption bindings) is AGPL-3.0.
  Handing the APK to others means offering them the app's source code. Either
  make the GitHub repository public and set `SOURCE_CODE_URL` in `.env`
  (shown in Settings > About), or replace the bindings before distributing.
  See README "Licensing" and SECURITY.md section 1.
- [ ] **(you) Privacy policy.** Fill in the bracketed placeholders in
  `PRIVACY_POLICY.md` (operator name, postal address, contact e-mail, minimum
  age), set the date, and publish it at a public URL (for example the file's
  GitHub link or GitHub Pages). The in-app copy is built from the same file,
  so rebuild afterwards.
- [ ] **(you) Security contact** in SECURITY.md section 7.

## 2. Supabase

- [ ] Database set up: `supabase/bvm_all_in_one.sql` run in the SQL Editor
  (contains all six migrations).
- [ ] Edge Functions deployed (`scripts\deploy-functions.ps1`); delete the
  personal access token afterwards (Account > Access Tokens).
- [ ] **Custom SMTP** configured. The built-in sender delivers only to team
  members and is limited to about 2 e-mails per hour.
- [ ] **Sign-up hook (required against sign-up spam):** Authentication >
  Hooks > *Before User Created* > Postgres > `public.bvm_before_user_created`.
  It refuses banned and throw-away e-mail domains and enforces the sign-up
  caps from the v6 migration (30 per hour, 150 per day, 1000 accounts in
  total), so spam sign-ups get no e-mail at all. Raise a cap later with e.g.
  `update private.settings set value = 2000 where key = 'max_accounts';`
- [ ] **Authentication > Rate Limits** (per-e-mail and per-IP limits that
  stop code-e-mail spam and code guessing):

  | Setting | Value |
  |---|---|
  | Rate limit for sending emails | 30 per hour |
  | Rate limit for sign-ups and sign-ins (per IP) | 15 per 5 minutes |
  | Rate limit for token verifications (per IP) | 15 per 5 minutes |
  | Rate limit for token refreshes (per IP) | default (150 per 5 minutes) |
  | Rate limit for anonymous users | 0 / leave anonymous sign-ins off |

  Mobile networks put many phones behind one IP address, so don't go much
  lower than 15.
- [ ] **Authentication > Sign In / Providers > Email**: OTP expiry 600
  seconds; minimum interval between e-mails to the same address 60 seconds
  (default). Leave every other provider (phone, Google, anonymous, ...)
  disabled.
- [ ] The app adds its own limits: a new code at most every 60 seconds and 5
  per hour from one phone, and 5 wrong codes before a new code is needed.
  Unfinished sign-ups are deleted after 24 hours.
- [ ] **Pausing.** Free projects with too little database activity in 7 days
  are paused, which takes BVM offline until you press *Resume project*. Either
  set up the keep-alive job (add the repository secrets `SUPABASE_URL` and
  `SUPABASE_PUBLISHABLE_KEY`, see `.github/workflows/supabase-keepalive.yml`,
  then run it once from the Actions tab) or use a paid plan. In a public
  repository, GitHub disables scheduled jobs after 60 days without repository
  activity; re-enable it in the Actions tab if that happens.
- [ ] **Backups.** Free-plan backups cannot be downloaded. If the database is
  lost, everyone must register again (messages are only on the phones and are
  not affected). For your own copy, run the portable `pg_dump` from
  `.toolchain\validation\pgsql\bin` with the connection string from
  Project Settings > Database. The dump contains e-mail addresses, encrypted
  phone numbers and encrypted account backups: keep it encrypted.
- [ ] Two-factor authentication on your Supabase, Google/Firebase and GitHub
  accounts.
- [ ] Look at Reports / Usage now and then against the Free-plan limits.

## 3. Firebase

- [ ] Keep the service-account JSON offline or delete it (a new key can be
  generated any time). If it leaks: Google Cloud console > IAM > Service
  accounts > Keys > delete it, generate a new one, rerun
  `deploy-functions.ps1 -ServiceAccount <new json>`.
- [ ] Optional hardening: Google Cloud console > APIs & Services >
  Credentials > the Android API key > restrict it to Android apps
  (`app.bvm.messenger` plus the SHA-1 of your upload key, from
  `keytool -list -v -keystore .secrets\upload-keystore.jks`; for Play
  installs also add the **app signing key** SHA-1 from Play Console > Test
  and release > Setup > App signing). Check that a message to a closed app
  still shows a notification afterwards.

## 4. Releases

- [ ] **Back up `.secrets\upload-keystore.jks` and `android\key.properties`**
  in two offline places. Without them, installed apps can never be updated.
- [ ] Raise `version:` in `pubspec.yaml` for every release (the part after
  `+` must grow; Android refuses to install an older code over a newer one).
- [ ] Publish the `.sha256` file next to the APK.
- [ ] Keep `build\symbols` of each release: the release build is
  obfuscated, and these files turn crash stack traces back into readable ones
  (`flutter symbolize`).

## 5. Test on real phones

Nothing below has been tested end to end on devices yet. Use two phones (or
one phone and an emulator with a "Google Play" image) and two accounts.

- [ ] Register both, find each other by username, chat both ways; receipts.
- [ ] Photo from gallery and camera; reply by swiping a message right (own
  and received) and by long-press; delete for everyone; search.
- [ ] Notification with BVM closed, within seconds (Firebase) and without
  Firebase (up to 15 minutes).
- [ ] Display name and profile picture appear on the other phone.
- [ ] Timer 1 day on a chat; secondary password unlock wipes that chat on both
  phones; the chat without a timer stays.
- [ ] Reinstall on one phone, sign in, enter the old password: contacts,
  name, picture and both passwords are back, chats empty; the other phone sees
  the security-code notice and messages flow again.
- [ ] "Start fresh" and "Forgot password".
- [ ] Block, unblock, report spam; message request banner.
- [ ] Username change; delete my account.
- [ ] Airplane mode: messages queue and go out when back online.

## 6. Tell your users

- One phone per account; signing in elsewhere moves the account.
- Chat history is never backed up. A new phone keeps contacts, not messages.
- A strong app password matters: it protects the encrypted account backup on
  the server.
- APK installs do not update themselves; tell people when a new version is out.

## 7. Secrets: what to keep, and where

| Item | Secret? | Where it lives | Keep a copy? |
|---|---|---|---|
| `.secrets\upload-keystore.jks` | **Yes** | Build laptop (git-ignored) | **Yes, 2 offline copies.** Without it no update can be uploaded (Play can reset an upload key, but only after a support request). |
| `android\key.properties` (keystore passwords) | **Yes** | Build laptop (git-ignored) | **Yes**, with the keystore. |
| Firebase service-account JSON | **Yes**, full push rights | Supabase secret `FCM_SERVICE_ACCOUNT` | No. Delete the download after deploying; generate a new key if you ever need it. |
| Supabase personal access token (`sbp_...`) | **Yes**, controls your projects | Nowhere | No. Create it for a deploy, delete it afterwards. |
| Supabase **secret** key (`sb_secret_...`) | **Yes**, bypasses all security | Supabase only | No. Never put it in `.env` or the app. |
| Supabase database password | **Yes** | Password manager | Yes. |
| SMTP / Gmail app password | **Yes** | Supabase SMTP settings | Password manager (or create a new one). |
| Supabase, Firebase/Google, GitHub, Play Console logins | **Yes** | Password manager, with 2-step verification on | Yes. |
| `.env`: `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `FIREBASE_*`, `SOURCE_CODE_URL` | No: built into the app, anyone can read them from the APK | Build laptop (git-ignored) | Yes, so you can rebuild; Row Level Security and the rate limits protect the server, not these values. |
| `google-services.json` | No (same values as `FIREBASE_*`) | Nowhere needed | No. |
| `build\symbols\` of each release | No | Build laptop | Yes, to read crash reports. |

How to store them:

- **Password manager** (Bitwarden is free, or KeePassXC offline): the account
  logins, the database password, the SMTP password, and the two values in
  `android\key.properties`. Attach `upload-keystore.jks` as a file there as
  well.
- **Offline copy**: put `.secrets\upload-keystore.jks`, `android\key.properties`
  and `.env` into an encrypted archive (7-Zip > Add to archive > AES-256, with
  a strong password from the password manager) and keep it on a USB stick
  and in one more place (for example a second drive or your private cloud
  drive; it's encrypted).
- **Never** commit them or send them in chat or e-mail. `.gitignore` already
  excludes `.env`, `.secrets/`, `*.jks`, `android/key.properties`,
  `google-services.json` and `*firebase-adminsdk*.json`; run `git status`
  before every commit to be sure.
- **GitHub keep-alive job**: `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` go
  into repository Settings > Secrets and variables > Actions, not into a
  file.

If one leaks: Firebase key: delete it in Google Cloud console > IAM >
Service accounts > Keys, generate a new one and rerun `deploy-functions.ps1
-ServiceAccount`. Supabase token: delete it under Account > Access Tokens.
Secret key or database password: rotate it in Project Settings. Keystore:
with Play App Signing, ask Play support to reset the upload key.

## 8. Capacity (limited public release)

The Free plan is enough for a limited release (roughly a few hundred active
users). What fills up, and what BVM does about it (plan limits as of
November 2026; check [supabase.com/pricing](https://supabase.com/pricing)):

| Resource (Free plan) | BVM usage | Guard |
|---|---|---|
| Database 500 MB | Directory, keys (~100 one-time keys per user, a few KB), account backups (16 KB per user), **undelivered envelopes** | Inbox quota 10 MB per recipient / 3 MB per sender-recipient pair; text 30 days, photos 7, receipts 3; inactive phones (30 days) purged. Delivered envelopes are deleted at once. |
| Egress 5 GB / month | Mostly photo parts (~300 KB per photo, sent once, fetched once) | Photos shrunk before sending. |
| Edge Function calls 500k / month | One `push` call per sent batch | Pushes coalesced to one per recipient per 5 s. |
| Realtime 200 concurrent | One connection per open app | Closed apps use push / the 15-minute check instead. |
| Auth e-mails | Your SMTP provider's limit | Supabase limit: 30 new users per hour (raise in Authentication > Rate Limits). |

Watch Reports > Database size in the dashboard. Worst case for undelivered
data is 10 MB times the number of users who stopped opening the app for
less than 30 days; with 100 such users that is 1 GB, so if you grow past a
few hundred users, either lower the quota in
`private.assert_inbox_space` (one SQL statement) or move to the Pro plan
(8 GB database, no pausing, about US$25 per month). No app change is needed
for either.

Check the current size of waiting data any time (SQL Editor):

```sql
select pg_size_pretty(sum(octet_length(ciphertext))) as waiting, count(*) as envelopes
  from public.relay;
```

## Not done yet (later)

- Phone-number verification (paid SMS/WhatsApp OTP).
- In-app "new version available" check for sideloaded APKs.
- Google Play (docs/PLAY_RELEASE.md) and iOS (docs/IOS.md).
