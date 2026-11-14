# M2: Google Play release checklist

Do this only after the M1 APK has been validated on real phones.

## Costs and account

* Google Play Console registration: **US$25, one time**. Personal accounts
  need identity verification.
* New **personal** developer accounts must run a **closed test with at least
  12 testers who stay opted in for 14 continuous days** before they can apply
  for production access. Organisation accounts are exempt.

## Build

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build-aab.ps1
```

Produces `dist\bvm-<version>-release.aab`, signed with the upload key from
`.secrets\`. Enrol in **Play App Signing** when creating the app: Google holds
the app signing key, our keystore becomes the upload key (resettable through
Play support if lost). Keep `build\symbols\` for each release to de-obfuscate
crash reports. Raise `version:` in `pubspec.yaml` for every upload.

## Store listing requirements

* **Privacy policy URL**: host `PRIVACY_POLICY.md` publicly (for example GitHub
  Pages, free) after filling in the placeholders.
* **Account deletion**: the in-app "Delete my account" exists. Play also
  requires a **web link** where users can request deletion without the app
  (a simple page or a monitored e-mail address is accepted).
* **Target API level**: targetSdk 36 (Flutter 3.47 default) meets the 2026
  requirement.
* **Content rating** questionnaire: messaging app with user-to-user
  communication.
* **Permissions**: INTERNET, POST_NOTIFICATIONS (plus WorkManager's
  RECEIVE_BOOT_COMPLETED / WAKE_LOCK and FCM's own). No sensitive permissions,
  so no declaration form.

## Data safety form (draft answers)

| Question | Answer |
|---|---|
| Does the app collect or share user data? | Collects; does not share. |
| Encrypted in transit? | Yes (TLS; messages also end-to-end encrypted). |
| Can users request deletion? | Yes, in the app and via the web link. |
| Personal info: e-mail address | Collected, required. Purpose: account management (sign-in codes). |
| Personal info: phone number | Collected, required. Purpose: account management. Stored encrypted. |
| Personal info: user ids (username) | Collected, required. Purpose: app functionality (discovery). |
| Photos | Same as messages: end-to-end encrypted, unreadable by the developer, held until delivery (at most 7 days). Metadata is stripped on the phone. |
| Messages: other in-app messages | Collected only as end-to-end-encrypted data that the developer cannot read, held until delivery. Google's guidance: data that is end-to-end encrypted and unreadable by the developer may be declared as not collected; review the current wording before answering. |
| Device or other ids | Firebase Installation ID for push, if push is enabled. Purpose: app functionality. |
| Location, contacts, photos, files, app activity, web history, health, financial | Not collected. |
| Analytics / advertising | None. |

## Closed test plan

1. Create the app, upload the AAB to **Testing > Closed testing**.
2. Add at least 12 testers (Google Group or e-mail list), share the opt-in link.
3. Keep them opted in for 14 days; collect feedback; ship fixes as new uploads.
4. Apply for production access with the answers about the test.
