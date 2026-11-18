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

- [ ] All four migrations run (`supabase/migrations/*.sql`, in name order).
- [ ] Edge Functions deployed (`scripts\deploy-functions.ps1`); delete the
  personal access token afterwards (Account > Access Tokens).
- [ ] **Custom SMTP** configured. The built-in sender delivers only to team
  members and is limited to about 2 e-mails per hour.
- [ ] Authentication > Rate Limits: with custom SMTP the default is 30 new
  users per hour; raise it before announcing the app widely.
- [ ] Authentication > Sign In / Providers > Email: shorten the OTP expiry
  (for example 600 seconds).
- [ ] Optional: Authentication > Hooks > *Before User Created* >
  `public.bvm_before_user_created` (banned addresses get no code at all).
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
  `keytool -list -v -keystore .secrets\upload-keystore.jks`). Check
  Settings > Notifications says "registered" afterwards.

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
- [ ] Photo from gallery and camera; reply; delete for everyone; search.
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

## Not done yet (later)

- CAPTCHA on sign-up (Supabase supports it; the app needs a CAPTCHA widget).
- Phone-number verification (paid SMS/WhatsApp OTP).
- In-app "new version available" check for sideloaded APKs.
- Google Play (docs/PLAY_RELEASE.md) and iOS (docs/IOS.md).
