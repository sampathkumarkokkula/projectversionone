# M3: iOS notes (out of MVP scope)

The Flutter code is platform-neutral; the `ios/` Runner was generated with the
project. What is still needed:

## Unavoidable cost

* **Apple Developer Program: US$99 per year** (the only recurring cost in the
  whole stack), plus a Mac with Xcode for building and signing.

## Platform work

| Topic | Android (done) | iOS (to do) |
|---|---|---|
| Screenshots | FLAG_SECURE blocks them | Cannot be blocked. Detect `userDidTakeScreenshotNotification` and blur sensitive views; screen recording can be detected via `UIScreen.isCaptured`. |
| App switcher | Blank thumbnail | The in-app privacy cover already shows when the app is inactive; verify it appears in the snapshot. |
| Backups | Excluded | Keychain items use `first_unlock_this_device` (not synced). Exclude the app support directory from iCloud backup (`NSURLIsExcludedFromBackupKey`). |
| E2E library | vodozemac via cargokit | flutter_vodozemac ships a prebuilt XCFramework for Swift Package Manager, so no Rust toolchain is needed on the Mac. |
| SQLCipher | sqlite3 hook | Same `package:sqlite3` hook (prebuilt iOS binaries exist); re-run `test/encrypted_database_test.dart` logic on a device during M3. |
| Push | FCM data message + local notification | FCM via APNs. iOS throttles data-only pushes; send an alert push with generic text ("New message") and `mutable-content` off. Requires an APNs key in Firebase. |
| Background sweep | WorkManager (15 min) | BGTaskScheduler through `workmanager`'s iOS support (best effort, OS decides). Expired messages are always hidden in the UI and swept on launch. |
| Keyboard incognito | IME flag | `autocorrectionType = no` / `spellCheckingType = no` (Flutter's `autocorrect`/`enableSuggestions` flags already map to these). |

## Licensing

App Store terms are widely considered incompatible with (A)GPL. Resolve the
vodozemac binding license question (SECURITY.md section 1) before submitting.
