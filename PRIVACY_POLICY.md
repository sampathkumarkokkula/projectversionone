# BVM Privacy Policy (draft)

Status: draft for review, version 0.1, 31 October 2026. Replace the bracketed
placeholders before publishing. Google Play requires this text at a public URL.

## Summary

BVM is a 1-to-1 text messenger. Messages are end-to-end encrypted on your
phone before they leave it. Your chat history is stored only on your phone and
on the phone of the person you talk to, never on our servers. We cannot read
your messages.

## Who is responsible

[Operator name, postal address, contact e-mail]

## What we store on our servers, and why

| Data | Purpose | How it is stored | How long |
|---|---|---|---|
| E-mail address | Sign-in with one-time codes | Supabase Auth, not visible to other users | Until you delete your account |
| Phone number | Collected at registration; verification is planned for a later version | Encrypted (AES-256) in a database area that is not reachable through the API | Until you delete your account |
| Username | Lets other people find you; this is the only thing others can search for | Public directory | Until you delete your account |
| Public encryption keys | Let other phones start an encrypted chat with you | Public directory | Until you delete your account or reinstall |
| Encrypted message envelopes | Delivery to the recipient's phone | Ciphertext only; deleted as soon as the recipient's phone has received it, at the latest after 30 days (earlier for messages with an auto-delete timer) | Minutes to at most 30 days |
| Encrypted photo parts | Delivery of photos | Ciphertext only, like messages; photos are stripped of location and camera data on your phone before encryption | Until delivered, at most 7 days |
| Encrypted profile picture | Showing your picture to people you chat with | Ciphertext only, sent to each of your chats like a message; we cannot see it and do not keep it | Until delivered |
| Username change time | Limiting changes to one per 24 hours | Directory | Until you delete your account |
| Your block list | Not delivering messages from people you blocked | Who blocked whom; not visible to other users and the blocked person is not told | Until you unblock or delete your account |
| Spam reports | Suspending accounts that several people report | Who reported whom and when; contains no messages | Until either account is deleted |
| Banned e-mail addresses | Keeping suspended spammers and throw-away addresses out | Only a SHA-256 hash of the address, plus a list of banned domains | Indefinitely |
| Inbox token | Letting your phone ask "are messages waiting?" for notifications while the app is closed | Only a hash of a random token; the check (about every 15 minutes) reveals to our provider's logs that your phone is online | Until you move to another phone or delete your account |
| Push address (Firebase Installation ID) | Waking the recipient's phone with a "you have a message" signal that contains no content | Not visible to other users | Until you delete your account |

Our infrastructure providers process technical data such as IP addresses and
request times in their logs to operate the service: Supabase (database,
sign-in, message relay) and Google Firebase Cloud Messaging (push signal).

## What we do not collect

- The content of your messages (we only ever handle ciphertext).
- Your chat history.
- Your contacts or address book.
- Your location.
- Online status or "last seen".
- Analytics, advertising identifiers or tracking.
- Your app passwords. Both the main and the optional secondary password are
  checked on your phone only and are never sent to us.

## Data on your phone

Chats, keys and settings are kept in an encrypted database (SQLCipher) whose
key is protected by the Android Keystore. App data is excluded from cloud
backups and device transfers. Screenshots and screen recording are blocked.

## Auto-delete and remote deletion

If you turn on the auto-delete timer in a chat, new messages are deleted from
both phones when the timer runs out. Some features (auto-delete, wipe
commands) also delete messages on the other person's phone; this depends on
the other phone running an unmodified BVM app.

## Your rights

You can delete your account at any time in Settings > Delete my account. This
removes your directory entry, keys, push address, inbox token, encrypted phone
number, e-mail address, block list, spam reports and undelivered messages from
our servers, and erases all BVM data on your phone. If your account was
suspended for spam, the hash of its e-mail address stays on the ban list. Copies that the people you chatted with keep on their own
phones are not affected.

You can also request deletion without the app at [URL or e-mail]. Depending on
where you live you may have further rights (access, correction, objection,
complaint to a data protection authority). Contact us at [contact e-mail].

## Children

BVM is not directed at children under 13 [or the minimum age in your country].

## Changes

We will announce material changes in the app before they take effect.
